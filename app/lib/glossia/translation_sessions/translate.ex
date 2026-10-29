defmodule Glossia.TranslationSessions.Translate do
  @moduledoc """
  Runs a repository translation session end to end.

  In a cluster this executes inside the detached Job that
  `Glossia.TranslationSessions.Launcher` scheduled for the session, so the run,
  the pull request it opens, and the status it records all outlive whatever web
  pod accepted the webhook. Outside a cluster it runs in the calling process.
  """

  import Ecto.Query

  require Logger

  alias Glossia.{Events, Ingestion, Repo, TranslationSessions}
  alias Glossia.Accounts.Project
  alias Glossia.Translations.Failure
  alias Glossia.Translations.Repository
  alias Glossia.TranslationSessions.PublicationBatch
  alias Glossia.TranslationSessions.PublicationPacing
  alias Glossia.TranslationSessions.PullRequestSummary
  alias Glossia.TranslationSessions.TranslationSession

  @translation_branch_prefix "glossia/translate"
  @translation_pull_request_title "feat(i18n): translate content"

  @doc """
  Fails a session that never got as far as running.

  Kept alongside the run so a session that could not be launched is recorded,
  announced and analysed exactly like one that failed mid-translation, rather
  than sitting in `pending` until the reaper notices it.
  """
  def fail_session(session_id, reason) do
    session =
      TranslationSessions.get_session!(session_id)
      |> Glossia.Repo.preload(project: [:account, :github_installation])

    fail_translation(session, session.project, session.project.account, reason)
  end

  def run(session_id) do
    session =
      TranslationSessions.get_session!(session_id)
      |> Glossia.Repo.preload(project: [:account, :github_installation])

    project = session.project
    account = project.account

    case TranslationSessions.start_session(session) do
      {:ok, started_session} -> do_run(started_session, project, account)
      {:error, :not_active} -> :ok
    end
  end

  defp do_run(%TranslationSession{} = session, project, account) do
    Events.emit("translation_session.started", account, nil,
      resource_type: "translation_session",
      resource_id: to_string(session.id),
      resource_path: "/#{account.handle}/#{project.handle}/-/sessions/#{session.id}",
      summary: "Translation session started for #{project.handle}"
    )

    with {:ok, token} <- get_clone_token(project),
         {:ok, session, token} <- prepare_run(session, project, token) do
      repository = repository(session, project, token)

      locales = session.target_languages || []
      batch = start_publication_batch(session, project, token)

      run_opts =
        case batch do
          nil -> []
          batch -> [after_item_completed: &PublicationBatch.add(batch, &1)]
        end

      try do
        run_result =
          Glossia.Translations.RepositoryRun.run(session, account, repository, locales, run_opts)

        case {run_result, flush_publication_batch(batch)} do
          {_run_result, {:error, :translation_cancelled}} ->
            :ok

          {{:ok, changes}, :ok} ->
            result = publication_result(session, project, token, changes)
            handle_translation_result(session, project, account, result)

          {{:ok, _changes}, {:error, reason}} ->
            fail_translation(session, project, account, {:translation_publication_failed, reason})

          {{:awaiting_input, changes}, :ok} ->
            case publication_result(session, project, token, changes) do
              {:error, reason} ->
                fail_translation(
                  session,
                  project,
                  account,
                  {:translation_publication_failed, reason}
                )

              _ ->
                Glossia.LinguisticReviews.pause(session.id)
            end

          {{:awaiting_input, _changes}, {:error, reason}} ->
            fail_translation(session, project, account, {:translation_publication_failed, reason})

          {{:error, reason}, {:error, publication_reason}} ->
            fail_translation(
              session,
              project,
              account,
              {:translation_and_publication_failed, reason, publication_reason}
            )

          {{:error, reason}, :ok} ->
            fail_translation(session, project, account, reason)
        end
      after
        if batch, do: PublicationBatch.stop(batch)
      end
    else
      {:error, :translation_cancelled} ->
        :ok

      {:error, reason} ->
        fail_translation(session, project, account, reason)
    end
  end

  defp prepare_run(session, %{github_installation: nil}, token),
    do: {:ok, session, token}

  defp prepare_run(session, _project, token) when token in [nil, ""],
    do: {:ok, session, token}

  defp prepare_run(session, project, token), do: prepare_run(session, project, token, true)

  defp prepare_run(session, project, token, retry_on_unauthorized?) do
    case do_prepare_run(session, project, token) do
      {:ok, updated_session} ->
        {:ok, updated_session, token}

      {:aborted, reason} ->
        {:error, {:publication_lock_aborted, reason}}

      {:error, {:api_error, 401, _body}}
      when retry_on_unauthorized? and not is_nil(project.github_installation) ->
        installation_id = project.github_installation.github_installation_id
        Glossia.Github.InstallationTokens.invalidate(installation_id)

        with {:ok, refreshed_token} <- Glossia.Github.App.installation_token(installation_id) do
          prepare_run(session, project, refreshed_token, false)
        end

      {:error, _reason} = error ->
        error
    end
  end

  defp do_prepare_run(session, project, token) do
    serialize_project_publication(project.id, fn ->
      fresh = TranslationSessions.get_session!(session.id)

      if fresh.status == "running" do
        recorded_session = fresh

        with {:ok, fresh} <- recover_open_publication(fresh, project, token),
             {:ok, fresh} <- continue_or_reset_publication(fresh, project, token),
             {:ok, remote} <- refresh_publication_head(fresh, project, token) do
          TranslationSessions.update_session_publication(recorded_session, %{
            publication_branch: remote.publication_branch,
            publication_commit_sha: remote.publication_commit_sha,
            pull_request_url: remote.pull_request_url,
            pull_request_number: remote.pull_request_number
          })
        end
      else
        {:error, :translation_cancelled}
      end
    end)
  end

  defp continue_or_reset_publication(session, project, token) do
    case refresh_inherited_pull_request(session, project, token) do
      {:reset, session} ->
        {:ok, session}

      {:ok, session} ->
        previous_session = TranslationSessions.get_session(session.continued_from_session_id)

        case compare_source_history(previous_session, session, project, token) do
          {:ok, status} when status in ["identical", "ahead"] ->
            {:ok, session}

          {:ok, status} when status in ["behind", "diverged"] ->
            {:error, :translation_source_history_changed}

          {:error, _reason} = error ->
            error

          _other ->
            {:error, :invalid_github_response}
        end

      {:error, _reason} = error ->
        error
    end
  end

  defp refresh_inherited_pull_request(
         %TranslationSession{pull_request_number: pull_request_number} = session,
         project,
         token
       )
       when is_integer(pull_request_number) do
    case Glossia.Github.Client.get_pull_request(
           project.github_repo_full_name,
           pull_request_number,
           token
         ) do
      {:ok, %{"state" => "open"} = pull_request} ->
        title = pull_request["title"]

        # Repair only our exact generated titles, leaving any reviewer-customized
        # title alone. Source commits belong in the pull request description.
        if is_binary(title) and
             title != @translation_pull_request_title and
             Regex.match?(
               ~r/\Afeat(?:\(i18n\))?: translate content(?: for [0-9a-f]{7})?\z/,
               title
             ) do
          case Glossia.Github.Client.update_pull_request(
                 project.github_repo_full_name,
                 pull_request_number,
                 %{title: @translation_pull_request_title},
                 token
               ) do
            {:ok, _pull_request} ->
              :ok

            {:error, reason} ->
              Logger.warning("Could not repair the translation pull request title",
                translation_session_id: session.id,
                reason: inspect(reason)
              )
          end
        end

        {:ok, session}

      # A merged pull request landed its translations, and a closed one was
      # rejected by someone on the project. Either way the next run starts a
      # fresh branch from the default branch rather than building on it.
      {:ok, %{"state" => "closed"}} ->
        with {:ok, session} <- reset_publication(session), do: {:reset, session}

      {:error, {:api_error, 404, _body}} ->
        with {:ok, session} <- reset_publication(session), do: {:reset, session}

      {:ok, _response} ->
        {:error, :invalid_github_response}

      {:error, _reason} = error ->
        error
    end
  end

  defp refresh_inherited_pull_request(session, _project, _token), do: {:ok, session}

  defp compare_source_history(
         _previous_session,
         %TranslationSession{continued_from_session_id: nil},
         _project,
         _token
       ),
       do: {:ok, "identical"}

  defp compare_source_history(
         %TranslationSession{commit_sha: previous_commit_sha},
         %TranslationSession{commit_sha: source_commit_sha},
         project,
         token
       )
       when is_binary(previous_commit_sha) and previous_commit_sha != "" and
              is_binary(source_commit_sha) and source_commit_sha != "" do
    with {:ok, comparison} <-
           Glossia.Github.Client.compare_commits(
             project.github_repo_full_name,
             previous_commit_sha,
             source_commit_sha,
             token
           ),
         status when is_binary(status) <- comparison["status"] do
      {:ok, status}
    else
      nil -> {:error, :invalid_github_response}
      {:error, _reason} = error -> error
    end
  end

  defp compare_source_history(_previous_session, _session, _project, _token),
    do: {:ok, "diverged"}

  # Always read the remote ref, not just the last saved SHA: an earlier API
  # request may have succeeded before its response or metadata was lost.
  defp refresh_publication_head(session, project, token) do
    branch = session.publication_branch || translation_branch_name(session)

    with {:ok, ref} <-
           Glossia.Github.Client.get_ref(
             project.github_repo_full_name,
             "heads/#{branch}",
             token
           ),
         sha when is_binary(sha) and sha != "" <- get_in(ref, ["object", "sha"]) do
      {:ok, %{session | publication_branch: branch, publication_commit_sha: sha}}
    else
      {:error, {:api_error, 404, _}} when is_nil(session.publication_commit_sha) -> {:ok, session}
      nil -> {:error, :invalid_github_response}
      "" -> {:error, :invalid_github_response}
      {:error, _reason} = error -> error
    end
  end

  defp repository(session, project, token) do
    %{
      full_name: project.github_repo_full_name,
      default_branch: project.github_repo_default_branch || "main",
      commit_sha: session.commit_sha,
      publication_branch: session.publication_commit_sha && session.publication_branch,
      publication_commit_sha: session.publication_commit_sha,
      token: token
    }
  end

  defp reset_publication(session) do
    TranslationSessions.update_session_publication(session, %{
      # A same-source retry must not rediscover the deliberately closed ref as
      # an orphan. Persist a fresh name before assessment or another attempt.
      publication_branch: "#{translation_branch_name(session)}-#{Ecto.UUID.generate()}",
      publication_commit_sha: nil,
      pull_request_url: nil,
      pull_request_number: nil
    })
  end

  defp get_clone_token(project) do
    installation = project.github_installation

    if is_nil(installation) do
      {:ok, nil}
    else
      case Glossia.Github.App.installation_token(installation.github_installation_id) do
        {:ok, token} ->
          {:ok, token}

        {:error, :not_configured} ->
          Logger.info(
            "GitHub App not configured, falling back to public clone for project #{project.id}"
          )

          {:ok, nil}

        {:error, reason} ->
          {:error, {:github_token_failed, reason}}
      end
    end
  end

  defp publication_result(session, project, clone_token, []) do
    fresh = TranslationSessions.get_session!(session.id)

    if fresh.publication_commit_sha && is_nil(fresh.pull_request_url) &&
         project.github_installation && is_binary(clone_token) && clone_token != "" do
      # A ref can survive a crash before PR creation. Assessment may already
      # find every lock up to date; reconcile the PR without advancing the ref.
      with {:ok, publication} <- publish_changes(%{session_id: session.id}, %{changes: []}) do
        {:published, publication.pull_request_url}
      end
    else
      :no_changes
    end
  end

  # Each validated item is published as a checkpoint while the run is still in
  # progress. The final change list remains a compatibility fallback for runs
  # created by an older worker, or for a runner that did not invoke the
  # checkpoint callback.
  defp publication_result(session, project, clone_token, changes)
       when not is_nil(project.github_installation) and is_binary(clone_token) and
              clone_token != "" do
    fresh = TranslationSessions.get_session!(session.id)

    case fresh.pull_request_url do
      pull_request_url when is_binary(pull_request_url) and pull_request_url != "" ->
        {:published, pull_request_url}

      _ ->
        with {:ok, _publication} <-
               publish_changes(%{session_id: session.id}, %{changes: changes}),
             updated <- TranslationSessions.get_session!(session.id),
             pull_request_url when is_binary(pull_request_url) and pull_request_url != "" <-
               updated.pull_request_url do
          {:published, pull_request_url}
        else
          nil -> {:error, :invalid_github_response}
          "" -> {:error, :invalid_github_response}
          {:error, _reason} = error -> error
        end
    end
  end

  defp publication_result(_session, _project, _clone_token, _changes), do: :skipped_pull_request

  @doc false
  def publish_changes(
        %{session_id: session_id},
        %{changes: changes},
        opts \\ []
      )
      when is_list(changes) do
    session =
      TranslationSessions.get_session!(session_id)
      |> Glossia.Repo.preload(project: [:account, :github_installation])

    case serialize_project_publication(session.project_id, fn ->
           fresh =
             TranslationSessions.get_session!(session_id)
             |> Glossia.Repo.preload(project: [:account, :github_installation])

           if fresh.status in ["pending", "running"] do
             if changes == [] and is_nil(fresh.publication_commit_sha),
               do: :ok,
               else: publish_changes_with_token(fresh, changes, true)
           else
             {:error, :translation_cancelled}
           end
         end) do
      {:aborted, reason} ->
        {:error, {:publication_lock_aborted, reason}}

      {:wait, ms} ->
        if Keyword.get(opts, :wait, true) do
          wait_for_publication(session_id, ms)
          publish_changes(%{session_id: session_id}, %{changes: changes}, opts)
        else
          TranslationSessions.heartbeat_session(session_id)
          {:wait, ms}
        end

      result ->
        result
    end
  end

  defp wait_for_publication(session_id, ms) do
    TranslationSessions.heartbeat_session(session_id)
    Process.sleep(min(ms, 30_000))
  end

  # Item workers run concurrently and hand their validated files to a batch,
  # which publishes them as one commit at a time. GitHub commits must form a
  # single linear history, so `publish_changes/2` still serializes each push
  # for the project before reading its latest published commit and advancing
  # the translation branch.
  defp start_publication_batch(session, project, clone_token)
       when not is_nil(project.github_installation) and is_binary(clone_token) and
              clone_token != "" do
    {:ok, batch} =
      PublicationBatch.start_link(fn changes ->
        publish_changes(%{session_id: session.id}, %{changes: changes}, wait: false)
      end)

    batch
  end

  defp start_publication_batch(_session, _project, _clone_token), do: nil

  defp flush_publication_batch(nil), do: :ok
  defp flush_publication_batch(batch), do: PublicationBatch.flush(batch)

  @doc false
  def serialize_project_publication(project_id, callback) do
    # Detached runners need not be connected to the same Erlang cluster.
    # Keep the project locked through GitHub's ref/PR updates AND persistence,
    # so supersession cannot inherit stale publication metadata mid-push.
    case Repo.transaction(
           fn ->
             Repo.one!(
               from(p in Project, where: p.id == ^project_id, lock: "FOR UPDATE"),
               timeout: :timer.minutes(10)
             )

             callback.()
           end,
           timeout: :timer.minutes(10)
         ) do
      {:ok, result} -> result
      {:error, reason} -> {:aborted, reason}
    end
  end

  defp publish_changes_with_token(session, changes, retry_on_unauthorized?) do
    installation = session.project.github_installation

    publish = fn ->
      with {:ok, token} <-
             Glossia.Github.App.installation_token(installation.github_installation_id) do
        do_publish_changes(session, session.project, token, changes)
      end
    end

    # An empty batch only repairs PR metadata for an existing ref. It cannot
    # advance that ref and must not spend a branch-update slot.
    result =
      if changes == [], do: publish.(), else: PublicationPacing.run(session.project_id, publish)

    case result do
      {:error, {:api_error, 401, _body}} when retry_on_unauthorized? ->
        Logger.warning("GitHub rejected an installation token, minting a new one",
          translation_session_id: session.id,
          github_installation_id: installation.github_installation_id
        )

        Glossia.Github.InstallationTokens.invalidate(installation.github_installation_id)

        # The first attempt may already have advanced the ref before a later
        # API call rejected the token. A retry consumes another paced slot.
        publish_changes_with_token(session, changes, false)

      result ->
        result
    end
  end

  defp do_publish_changes(session, project, token, changes) do
    full_name = project.github_repo_full_name
    default_branch = project.github_repo_default_branch || "main"
    recorded_session = session

    with {:ok, session} <- recover_open_publication(session, project, token),
         {:ok, session} <- refresh_publication_head(session, project, token),
         branch_name = session.publication_branch || translation_branch_name(session),
         {:ok, parent_commit_sha} <-
           base_commit_sha(full_name, default_branch, session, token),
         repository = repository(session, project, token),
         repository = %{repository | commit_sha: repository.commit_sha || parent_commit_sha},
         repository =
           Map.put(
             repository,
             :expected_publication_commit_sha,
             recorded_session.publication_commit_sha || repository.commit_sha
           ),
         {:ok, prepared} <- Repository.prepare_publication(repository, changes),
         {:ok, commit_sha} <-
           publish_prepared_changes(session, full_name, branch_name, token, prepared),
         {:ok, pull_request_url, pull_request_created?, pull_request_number} <-
           ensure_pull_request(
             session,
             full_name,
             default_branch,
             branch_name,
             token
           ),
         {:ok, updated_session} <-
           TranslationSessions.update_session_publication(recorded_session, %{
             publication_branch: branch_name,
             publication_commit_sha: commit_sha,
             pull_request_url: pull_request_url,
             pull_request_number: pull_request_number
           }) do
      if pull_request_created? do
        record_translation_event(updated_session, %{
          "event_type" => "pr_created",
          "content" => pull_request_url,
          "metadata" => %{"repo" => full_name}
        })
      else
        refresh_pull_request_description(updated_session, token)
      end

      {:ok, %{ref: branch_name, pull_request_url: pull_request_url}}
    else
      nil -> {:error, :invalid_github_response}
      other -> other
    end
  end

  defp publish_prepared_changes(_session, _full_name, _branch_name, _token, %{
         changes: [],
         parents: [parent]
       }),
       do: {:ok, parent}

  defp publish_prepared_changes(session, full_name, branch_name, token, prepared) do
    with {:ok, parent_commit} <-
           Glossia.Github.Client.get_commit(full_name, hd(prepared.parents), token),
         base_tree_sha when is_binary(base_tree_sha) <- get_in(parent_commit, ["tree", "sha"]),
         {:ok, tree_entries} <- create_tree_entries(full_name, token, prepared.changes),
         {:ok, tree} <-
           Glossia.Github.Client.create_tree(
             full_name,
             %{base_tree: base_tree_sha, tree: tree_entries},
             token
           ),
         tree_sha when is_binary(tree_sha) <- tree["sha"],
         {:ok, commit} <-
           Glossia.Github.Client.create_commit(
             full_name,
             %{
               message: translation_commit_message(session),
               tree: tree_sha,
               parents: prepared.parents
             },
             token
           ),
         commit_sha when is_binary(commit_sha) <- commit["sha"],
         :ok <- publish_branch(session, full_name, branch_name, commit_sha, token) do
      {:ok, commit_sha}
    else
      nil -> {:error, :invalid_github_response}
      other -> other
    end
  end

  # GitHub can accept a PR just before the runner dies or its database
  # transaction fails. Recover that publication before creating a new one,
  # rather than relying solely on metadata from a previous session.
  defp recover_open_publication(%{pull_request_url: url} = session, _project, _token)
       when is_binary(url) and url != "",
       do: {:ok, session}

  defp recover_open_publication(session, project, token) do
    with {:ok, pull_request} <- find_open_translation_pull_request(project, token, 1) do
      case pull_request do
        nil ->
          {:ok, session}

        %{
          "head" => %{"ref" => branch, "sha" => sha},
          "html_url" => url,
          "number" => number
        }
        when is_binary(branch) and is_binary(sha) and is_binary(url) and is_integer(number) ->
          {:ok,
           %{
             session
             | publication_branch: branch,
               publication_commit_sha: sha,
               pull_request_url: url,
               pull_request_number: number
           }}

        _ ->
          {:error, :invalid_github_response}
      end
    end
  end

  defp find_open_translation_pull_request(project, token, page) do
    app_slug = Application.get_env(:glossia, Glossia.Github.App, [])[:app_slug] || "glossia"
    bot_login = "#{app_slug}[bot]"

    case Glossia.Github.Client.list_pull_requests(project.github_repo_full_name, token,
           base: project.github_repo_default_branch || "main",
           page: page,
           per_page: 100
         ) do
      {:ok, pull_requests} when is_list(pull_requests) ->
        existing =
          Enum.find(pull_requests, fn pr ->
            get_in(pr, ["user", "login"]) == bot_login and
              get_in(pr, ["head", "repo", "full_name"]) == project.github_repo_full_name and
              is_binary(get_in(pr, ["head", "ref"])) and
              String.starts_with?(get_in(pr, ["head", "ref"]), @translation_branch_prefix <> "-")
          end)

        cond do
          existing ->
            {:ok, existing}

          length(pull_requests) == 100 ->
            find_open_translation_pull_request(project, token, page + 1)

          true ->
            {:ok, nil}
        end

      {:ok, _} ->
        {:error, :invalid_github_response}

      {:error, _} = error ->
        error
    end
  end

  defp base_commit_sha(
         _full_name,
         _default_branch,
         %TranslationSession{publication_commit_sha: sha},
         _token
       )
       when is_binary(sha) and sha != "" do
    {:ok, sha}
  end

  defp base_commit_sha(_full_name, _default_branch, %TranslationSession{commit_sha: sha}, _token)
       when is_binary(sha) and sha != "" do
    {:ok, sha}
  end

  defp base_commit_sha(full_name, default_branch, _session, token) do
    with {:ok, ref_data} <-
           Glossia.Github.Client.get_ref(full_name, "heads/#{default_branch}", token),
         sha when is_binary(sha) <- get_in(ref_data, ["object", "sha"]) do
      {:ok, sha}
    else
      nil -> {:error, :invalid_github_response}
      other -> other
    end
  end

  defp create_tree_entries(full_name, token, changes) do
    changes
    |> Enum.reduce_while({:ok, []}, fn
      %{path: path, status: "deleted"}, {:ok, entries} ->
        entry = %{path: path, mode: "100644", type: "blob", sha: nil}
        {:cont, {:ok, [entry | entries]}}

      %{path: path, mode: mode, type: "commit", sha: sha}, {:ok, entries} ->
        {:cont, {:ok, [%{path: path, mode: mode, type: "commit", sha: sha} | entries]}}

      %{path: path, content: content} = change, {:ok, entries} ->
        params = %{content: Base.encode64(content), encoding: "base64"}

        case Glossia.Github.Client.create_blob(full_name, params, token) do
          {:ok, %{"sha" => sha}} ->
            entry = %{path: path, mode: Map.get(change, :mode, "100644"), type: "blob", sha: sha}
            {:cont, {:ok, [entry | entries]}}

          {:ok, _response} ->
            {:halt, {:error, :invalid_github_response}}

          {:error, reason} ->
            {:halt, {:error, reason}}
        end
    end)
    |> case do
      {:ok, entries} -> {:ok, Enum.reverse(entries)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp publish_branch(
         %TranslationSession{publication_commit_sha: sha},
         full_name,
         branch_name,
         commit_sha,
         token
       )
       when is_binary(sha) and sha != "" do
    case Glossia.Github.Client.update_ref(
           full_name,
           "heads/#{branch_name}",
           commit_sha,
           token
         ) do
      {:ok, _} -> :ok
      {:error, _reason} = error -> error
    end
  end

  defp publish_branch(_session, full_name, branch_name, commit_sha, token) do
    create_or_update_branch(full_name, branch_name, commit_sha, token)
  end

  defp create_or_update_branch(full_name, branch_name, sha, token) do
    case Glossia.Github.Client.create_branch(full_name, branch_name, sha, token) do
      {:ok, _} ->
        :ok

      {:error, {:api_error, 422, _body}} ->
        case Glossia.Github.Client.update_ref(full_name, "heads/#{branch_name}", sha, token,
               force: false
             ) do
          {:ok, _} -> :ok
          {:error, _reason} = error -> error
        end

      {:error, _reason} = error ->
        error
    end
  end

  defp ensure_pull_request(
         %TranslationSession{
           pull_request_url: pull_request_url,
           pull_request_number: pull_request_number
         },
         _full_name,
         _default_branch,
         _branch_name,
         _token
       )
       when is_binary(pull_request_url) and pull_request_url != "" do
    {:ok, pull_request_url, false, pull_request_number}
  end

  defp ensure_pull_request(session, full_name, default_branch, branch_name, token) do
    case Glossia.Github.Client.create_pull_request(
           full_name,
           %{
             title: @translation_pull_request_title,
             body: pull_request_description(%{session | publication_branch: branch_name}),
             head: branch_name,
             base: default_branch
           },
           token
         ) do
      {:ok, %{"html_url" => pull_request_url, "number" => pull_request_number}}
      when is_binary(pull_request_url) and is_integer(pull_request_number) ->
        {:ok, pull_request_url, true, pull_request_number}

      {:ok, %{"html_url" => pull_request_url}} when is_binary(pull_request_url) ->
        {:ok, pull_request_url, true, nil}

      {:ok, _response} ->
        {:error, :invalid_github_response}

      {:error, _reason} = error ->
        error
    end
  end

  defp handle_translation_result(session, project, account, {:published, _pull_request_url}) do
    summary = "Updated translation pull request."

    with {:ok, finished} <-
           TranslationSessions.finish_session(session, "completed", summary: summary) do
      refresh_pull_request_description(finished)

      Events.emit("translation_session.completed", account, nil,
        resource_type: "translation_session",
        resource_id: to_string(session.id),
        resource_path: "/#{account.handle}/#{project.handle}/-/sessions/#{session.id}",
        summary: "Translation session completed for #{project.handle}"
      )
    end

    :ok
  end

  defp handle_translation_result(session, project, account, :skipped_pull_request) do
    summary = "Translation completed. Pull request skipped because GitHub is not configured."

    with {:ok, _session} <-
           TranslationSessions.finish_session(session, "completed", summary: summary) do
      Events.emit("translation_session.completed", account, nil,
        resource_type: "translation_session",
        resource_id: to_string(session.id),
        resource_path: "/#{account.handle}/#{project.handle}/-/sessions/#{session.id}",
        summary: "Translation session completed for #{project.handle}"
      )
    end

    :ok
  end

  defp handle_translation_result(session, project, account, :no_changes) do
    summary = "No translations needed."

    with {:ok, _session} <-
           TranslationSessions.finish_session(session, "completed",
             summary: summary,
             outcome: "content_hit"
           ) do
      record_translation_event(session, %{
        "event_type" => "status",
        "content" => summary,
        "metadata" => %{}
      })

      Events.emit("translation_session.completed", account, nil,
        resource_type: "translation_session",
        resource_id: to_string(session.id),
        resource_path: "/#{account.handle}/#{project.handle}/-/sessions/#{session.id}",
        summary: "Translation session completed for #{project.handle}: no translations needed"
      )
    end

    :ok
  end

  defp handle_translation_result(session, _project, _account, {:error, reason}) do
    fail_translation(
      session,
      session.project,
      session.account,
      {:translation_publication_failed, reason}
    )
  end

  defp fail_translation(session, project, account, reason) do
    error_msg = humanize_error(reason)
    failure_metadata = failure_metadata(reason)

    case TranslationSessions.finish_session(session, "failed",
           error: error_msg,
           failure_kind: failure_metadata["failure_kind"]
         ) do
      {:ok, finished_session} ->
        refresh_pull_request_description(finished_session)

        if Glossia.TranslationSessions.ProviderRecovery.retryable_provider_failure?(reason) do
          Glossia.TranslationSessions.ProviderRecovery.schedule(finished_session)
        end

        Logger.error(
          "Translation session failed: " <>
            JSON.encode!(
              Map.merge(failure_metadata, %{
                "event" => "translation.session_failed",
                "translation_session_id" => session.id,
                "project_id" => project.id
              })
            )
        )

        record_translation_event(session, %{
          "event_type" => "error",
          "content" => error_msg,
          "metadata" => failure_metadata
        })

        Events.emit("translation_session.failed", account, nil,
          resource_type: "translation_session",
          resource_id: to_string(session.id),
          resource_path: "/#{account.handle}/#{project.handle}/-/sessions/#{session.id}",
          summary:
            "Translation session failed for #{project.handle}: #{String.slice(error_msg, 0, 200)}"
        )

        {:error, reason}

      {:error, :not_active} ->
        :ok
    end
  end

  defp record_translation_event(session, %{"event_type" => event_type} = event)
       when is_binary(event_type) do
    content = Map.get(event, "content", "")
    metadata = Map.get(event, "metadata", %{})
    record_translation_event(session, event_type, content, metadata)
  end

  defp record_translation_event(_session, _event), do: :ok

  defp record_translation_event(session, event_type, content, metadata) do
    sequence = next_translation_event_sequence(session)
    metadata_json = encode_event_metadata(metadata)

    Ingestion.record_translation_session_event(
      session.id,
      sequence,
      event_type,
      content || "",
      metadata_json
    )

    TranslationSessions.broadcast_session_event(session, %{
      sequence: sequence,
      event_type: event_type,
      content: content || "",
      metadata: metadata_json
    })
  end

  defp encode_event_metadata(metadata) when is_binary(metadata), do: metadata
  defp encode_event_metadata(metadata), do: JSON.encode!(metadata || %{})

  defp failure_metadata({:translation_items_failed, failures}) when is_list(failures) do
    max_items = 100
    persisted_items = failures |> Enum.take(max_items) |> Enum.map(&item_failure_metadata/1)

    %{
      "failure_kind" => "translation_items_failed",
      "failure_count" => length(failures),
      "recorded_failure_count" => length(persisted_items),
      "omitted_failure_count" => max(length(failures) - length(persisted_items), 0),
      "items" => persisted_items
    }
  end

  defp failure_metadata({:translation_publication_failed, _reason} = reason) do
    failure = Failure.from(reason)

    %{
      "failure_kind" => "translation_publication_failed",
      "publication_code" => failure.publication_code,
      "publication_message" => failure.publication_message,
      "publication_file_error" => Map.get(failure, :publication_file_error)
    }
  end

  defp failure_metadata({:translation_and_publication_failed, reason, publication_reason}) do
    %{
      "failure_kind" => "translation_and_publication_failed",
      "translation_failure" => failure_metadata(reason),
      "publication_failure" =>
        failure_metadata({:translation_publication_failed, publication_reason})
    }
  end

  defp failure_metadata(:translation_branch_conflict),
    do: %{"failure_kind" => "translation_branch_conflict"}

  defp failure_metadata(_reason), do: %{"failure_kind" => "translation_failed"}

  defp item_failure_metadata(item) when is_map(item) do
    failure = Failure.normalize(Map.get(item, :reason))
    diagnostics = Map.get(item, :diagnostics, %{})

    %{
      "index" => Map.get(item, :index),
      "source_path" => Map.get(diagnostics, :source_path),
      "output_path" => Map.get(item, :output_path),
      "locale" => Map.get(item, :locale),
      "format" => Map.get(diagnostics, :format),
      "frontmatter_mode" => diagnostics |> Map.get(:frontmatter_mode) |> to_string(),
      "model" => Map.get(diagnostics, :model),
      "provider" => failure.provider || Map.get(diagnostics, :provider),
      "failure_kind" => failure.kind,
      "failure_scope" => failure.scope,
      "validation_code" => Map.get(failure, :validation_code),
      "validation_message" => Map.get(failure, :validation_message),
      "validation_exit_status" => Map.get(failure, :validation_exit_status),
      "publication_code" => Map.get(failure, :publication_code),
      "publication_message" => Map.get(failure, :publication_message),
      "publication_file_error" => Map.get(failure, :publication_file_error),
      "provider_status" => failure.status,
      "provider_error_code" => failure.code,
      "provider_request_id" => failure.request_id
    }
  end

  defp item_failure_metadata(_item), do: %{"failure_kind" => "translation-failed"}

  defp next_translation_event_sequence(session) do
    key = {__MODULE__, :translation_event_sequence, session.id}

    sequence =
      (Process.get(key) || Ingestion.max_translation_session_event_sequence(session.id)) + 1

    Process.put(key, sequence)
    sequence
  end

  defp translation_branch_name(%TranslationSession{} = session) do
    suffix =
      case session.commit_sha do
        sha when is_binary(sha) and byte_size(sha) >= 7 -> String.slice(sha, 0, 12)
        _ -> session.id |> to_string() |> String.slice(0, 12)
      end

    "#{@translation_branch_prefix}-#{suffix}"
  end

  defp translation_commit_message(%TranslationSession{} = session) do
    case session.commit_sha do
      sha when is_binary(sha) and byte_size(sha) >= 7 ->
        "feat(i18n): translate content for #{String.slice(sha, 0, 7)}"

      _ ->
        "feat(i18n): translate content"
    end
  end

  defp pull_request_description(session) do
    PullRequestSummary.body(session)
  rescue
    error ->
      Logger.warning("Could not summarize the translation pull request",
        translation_session_id: session.id,
        reason: Exception.message(error)
      )

      "Glossia is translating this repository's content. The summary could not be generated."
  end

  # The pull request description summarizes every run on the branch, so it is
  # rewritten whenever the branch moves and when a run ends. It is a courtesy
  # to reviewers: failing to update it never fails the translation.
  defp refresh_pull_request_description(%TranslationSession{id: session_id}) do
    session =
      session_id
      |> TranslationSessions.get_session!()
      |> Glossia.Repo.preload(project: [:account, :github_installation])

    with number when is_integer(number) <- session.pull_request_number,
         %{github_installation_id: installation_id} <- session.project.github_installation,
         {:ok, token} <- Glossia.Github.App.installation_token(installation_id) do
      refresh_pull_request_description(session, token)
    else
      _ -> :ok
    end
  end

  defp refresh_pull_request_description(
         %TranslationSession{pull_request_number: number} = session,
         token
       )
       when is_integer(number) do
    session = Glossia.Repo.preload(session, project: [:account])

    case Glossia.Github.Client.update_pull_request(
           session.project.github_repo_full_name,
           number,
           %{body: pull_request_description(session)},
           token
         ) do
      {:ok, _pull_request} ->
        :ok

      {:error, reason} ->
        Logger.warning("Could not update the translation pull request description",
          translation_session_id: session.id,
          reason: inspect(reason)
        )

        :ok
    end
  end

  defp refresh_pull_request_description(_session, _token), do: :ok

  defp humanize_error(:translation_harness_failed),
    do: "The translation harness encountered an error and could not complete."

  defp humanize_error(:translation_harness_timeout),
    do: "The translation harness timed out before completing."

  defp humanize_error(:runner_timeout),
    do: "Translation stopped because the isolated runner timed out. Please retry."

  defp humanize_error({:runner_exit, _reason}),
    do: "Translation stopped unexpectedly in the isolated runner. Please retry."

  defp humanize_error({:translation_job_launch_failed, :engine_rollout_timeout}),
    do:
      "Translation recovery could not start because the engine rollout did not complete in time."

  defp humanize_error({:translation_job_launch_failed, :engine_already_attempted}),
    do: "Translation recovery was stopped because the deployed engine was already attempted."

  defp humanize_error({:translation_job_launch_failed, {:engine_release_unavailable, _reason}}),
    do:
      "Translation recovery could not verify the deployed engine. Check the Deployment configuration and Kubernetes API permissions."

  defp humanize_error({:translation_job_launch_failed, _reason}),
    do: "Could not start the translation runner. Please retry."

  defp humanize_error(:translation_abandoned),
    do:
      "The translation stopped reporting progress and was ended. This usually means its runner was lost. Please retry."

  # A run stops at the first permanent provider failure, so the failure list can
  # be a single item whose cause is the provider rather than the file it names.
  # Report that cause: counting files sends a member to inspect content that is
  # fine while the real fix is a credit balance or a key.
  defp humanize_error({:translation_items_failed, failures}) when is_list(failures) do
    case Enum.find(failures, &run_stopping_failure?/1) do
      nil ->
        count = length(failures)
        suffix = if count == 1, do: "file", else: "files"
        "Translation failed for #{count} #{suffix}. Review the file errors and retry."

      failure ->
        failure |> Map.get(:reason) |> Failure.describe()
    end
  end

  defp humanize_error({:context_relay_failed, _reason}),
    do: "Could not load the account's translation context. Please retry."

  defp humanize_error({:github_token_failed, _}),
    do: "Could not authenticate with GitHub. Check the app installation."

  defp humanize_error(:sandboxes_disabled), do: "Sandbox workflow execution is disabled."

  defp humanize_error(:sandbox_quota_exceeded),
    do: "The account has reached its active sandbox limit."

  defp humanize_error(:translation_change_manifest_missing),
    do: "The translation harness did not report the files it changed."

  defp humanize_error(:translation_change_manifest_empty),
    do: "The translation harness reported an empty changed-file manifest."

  defp humanize_error(:translation_change_manifest_invalid),
    do: "The translation harness reported an invalid changed-file manifest."

  defp humanize_error({:translation_changed_file_missing, path}),
    do:
      "The translation harness reported #{path}, but that file could not be read from the sandbox."

  defp humanize_error(:translation_lockfile_invalid),
    do: "The translation harness reported an invalid Glossia lockfile."

  defp humanize_error({:translation_publication_failed, _reason} = reason),
    do: reason |> Failure.from() |> Failure.describe()

  defp humanize_error({:translation_and_publication_failed, reason, publication_reason}),
    do:
      humanize_error(reason) <>
        " " <> humanize_error({:translation_publication_failed, publication_reason})

  defp humanize_error({:translation_pull_request_closed, pull_request_number}),
    do:
      "Translation pull request ##{pull_request_number} was closed without merging. Reopen it or start another translation."

  defp humanize_error(:codex_session_token_missing),
    do: "Could not read a local Codex session token for development translation."

  defp humanize_error(reason), do: Glossia.TranslationSessions.Error.describe(reason)

  defp run_stopping_failure?(%{reason: reason}),
    do: reason |> Failure.normalize() |> Failure.run_stopping?()

  defp run_stopping_failure?(_failure), do: false
end
