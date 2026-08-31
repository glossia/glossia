defmodule Glossia.TranslationSessions.Translate do
  @moduledoc """
  Runs a repository translation session end to end.

  In a cluster this executes inside the detached Job that
  `Glossia.TranslationSessions.Launcher` scheduled for the session, so the run,
  the pull request it opens, and the status it records all outlive whatever web
  pod accepted the webhook. Outside a cluster it runs in the calling process.
  """

  require Logger

  alias Glossia.{Events, Ingestion, TranslationSessions}
  alias Glossia.Translations.Failure
  alias Glossia.TranslationSessions.TranslationSession

  @translation_branch_prefix "glossia/translate"

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

    if session.status == "cancelled" do
      :ok
    else
      do_run(session, project, account)
    end
  end

  defp do_run(%TranslationSession{} = session, project, account) do
    TranslationSessions.update_session_status(session, "running")

    Events.emit("translation_session.started", account, nil,
      resource_type: "translation_session",
      resource_id: to_string(session.id),
      resource_path: "/#{account.handle}/#{project.handle}/-/sessions/#{session.id}",
      summary: "Translation session started for #{project.handle}"
    )

    with {:ok, token} <- get_clone_token(project) do
      repository = %{
        full_name: project.github_repo_full_name,
        default_branch: project.github_repo_default_branch || "main",
        commit_sha: session.commit_sha,
        token: token
      }

      locales = session.target_languages || []

      run_opts =
        case publication_callback(session, project, token) do
          nil -> []
          callback -> [after_item_completed: callback]
        end

      case Glossia.Translations.RepositoryRun.run(session, account, repository, locales, run_opts) do
        {:ok, changes} ->
          result = publication_result(session, project, token, changes)
          handle_translation_result(session, project, account, result)

        {:error, reason} ->
          fail_translation(session, project, account, reason)
      end
    else
      {:error, reason} ->
        fail_translation(session, project, account, reason)
    end
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

  defp publication_result(_session, _project, _clone_token, []), do: :no_changes

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
        %{changes: changes}
      )
      when is_list(changes) do
    session =
      TranslationSessions.get_session!(session_id)
      |> Glossia.Repo.preload(project: [:account, :github_installation])

    publish_changes_with_token(session, changes, true)
  end

  # Item workers run concurrently. GitHub commits must form a single linear
  # history, so serialize checkpoints for one session before reading its latest
  # published commit and advancing the translation branch.
  defp publication_callback(session, project, clone_token)
       when not is_nil(project.github_installation) and is_binary(clone_token) and
              clone_token != "" do
    fn changes ->
      serialize_checkpoint(session.id, fn ->
        fresh = TranslationSessions.get_session!(session.id)

        if fresh.status == "running" do
          publish_changes(%{session_id: session.id}, %{changes: changes})
        else
          {:error, :translation_cancelled}
        end
      end)
    end
  end

  defp publication_callback(_session, _project, _clone_token), do: nil

  defp serialize_checkpoint(session_id, callback) do
    if Node.alive?() do
      # `:global.trans/2` expects `{resource, requester}`. The previous
      # three-element tuple is rejected on distributed worker nodes before the
      # callback can publish anything. Keeping the session in the resource and
      # the process as requester serializes a session's commits while allowing
      # independent sessions to publish at the same time.
      :global.trans({{__MODULE__, :translation_checkpoint, session_id}, self()}, callback)
    else
      callback.()
    end
  end

  defp publish_changes_with_token(session, changes, retry_on_unauthorized?) do
    installation = session.project.github_installation

    with {:ok, token} <-
           Glossia.Github.App.installation_token(installation.github_installation_id) do
      case do_publish_changes(session, session.project, token, changes) do
        # GitHub rejected a token we believed was live, so it either expired
        # between the cache handing it over and the request landing, or it was
        # revoked. Drop it and mint a new one before failing the run, since
        # giving up here discards every translation the run has produced.
        {:error, {:api_error, 401, _body}} when retry_on_unauthorized? ->
          Logger.warning("GitHub rejected an installation token, minting a new one",
            translation_session_id: session.id,
            github_installation_id: installation.github_installation_id
          )

          Glossia.Github.InstallationTokens.invalidate(installation.github_installation_id)
          publish_changes_with_token(session, changes, false)

        result ->
          result
      end
    end
  end

  defp do_publish_changes(session, project, token, changes) do
    full_name = project.github_repo_full_name
    default_branch = project.github_repo_default_branch || "main"
    commit_message = translation_commit_message(session)

    with branch_name = session.publication_branch || translation_branch_name(session),
         {:ok, parent_commit_sha} <-
           base_commit_sha(full_name, default_branch, session, token),
         {:ok, parent_commit} <-
           Glossia.Github.Client.get_commit(full_name, parent_commit_sha, token),
         base_tree_sha when is_binary(base_tree_sha) <- get_in(parent_commit, ["tree", "sha"]),
         {:ok, tree_entries} <- create_tree_entries(full_name, token, changes),
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
               message: commit_message,
               tree: tree_sha,
               parents: [parent_commit_sha]
             },
             token
           ),
         commit_sha when is_binary(commit_sha) <- commit["sha"],
         :ok <- publish_branch(session, full_name, branch_name, commit_sha, token),
         {:ok, pull_request_url, pull_request_created?, pull_request_number} <-
           ensure_pull_request(
             session,
             full_name,
             default_branch,
             branch_name,
             token
           ),
         {:ok, updated_session} <-
           TranslationSessions.update_session_publication(session, %{
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
      end

      {:ok, %{ref: branch_name, pull_request_url: pull_request_url}}
    else
      nil -> {:error, :invalid_github_response}
      other -> other
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

      %{path: path, content: content}, {:ok, entries} ->
        params = %{content: Base.encode64(content), encoding: "base64"}

        case Glossia.Github.Client.create_blob(full_name, params, token) do
          {:ok, %{"sha" => sha}} ->
            entry = %{path: path, mode: "100644", type: "blob", sha: sha}
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
             title: translation_commit_message(session),
             body: pull_request_body(session),
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

    with {:ok, _session} <-
           TranslationSessions.update_session_status(session, "completed", summary: summary) do
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
           TranslationSessions.update_session_status(session, "completed", summary: summary) do
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
           TranslationSessions.update_session_status(session, "completed", summary: summary) do
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

    TranslationSessions.update_session_status(session, "failed", error: error_msg)

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

  defp failure_metadata({:translation_publication_failed, _reason}) do
    %{"failure_kind" => "translation_publication_failed"}
  end

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
        "feat: translate content for #{String.slice(sha, 0, 7)}"

      _ ->
        "feat: translate content"
    end
  end

  defp pull_request_body(session) do
    languages =
      case session.target_languages || [] do
        [] -> "The translation run used the targets declared in `GLOSSIA.md`."
        targets -> "Target languages: " <> Enum.join(targets, ", ") <> "."
      end

    commit =
      case session.commit_sha do
        sha when is_binary(sha) and sha != "" -> "Source commit: `#{sha}`."
        _ -> "Source commit was not specified."
      end

    """
    ## What changed

    Glossia is translating stale or missing localized content and updating the corresponding `.glossia/` lockfiles. Each validated file is committed to this pull request as soon as it completes.

    ## Why

    #{languages}
    #{commit}

    ## Approach

    The translation harness runs inside a sandbox, uses `GLOSSIA.md` to build the translation plan, and lets the lockfiles decide which outputs need work. The branch is updated incrementally while the session is running.

    ## Impact

    Reviewers should check the translated copy and keep the lockfile changes with the translated files.

    ## Validation

    Every committed file passed the translation validation before publication. More commits can appear until the session is complete.
    """
  end

  defp humanize_error(:translation_harness_failed),
    do: "The translation harness encountered an error and could not complete."

  defp humanize_error(:translation_harness_timeout),
    do: "The translation harness timed out before completing."

  defp humanize_error(:runner_timeout),
    do: "Translation stopped because the isolated runner timed out. Please retry."

  defp humanize_error({:runner_exit, _reason}),
    do: "Translation stopped unexpectedly in the isolated runner. Please retry."

  defp humanize_error({:translation_job_launch_failed, _reason}),
    do: "Could not start the translation runner. Please retry."

  defp humanize_error(:translation_abandoned),
    do:
      "The translation stopped reporting progress and was ended. This usually means its runner was lost. Please retry."

  defp humanize_error({:translation_items_failed, failures}) when is_list(failures) do
    count = length(failures)
    suffix = if count == 1, do: "file", else: "files"
    "Translation failed for #{count} #{suffix}. Review the file errors and retry."
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

  defp humanize_error({:translation_publication_failed, reason}),
    do: "The translation pull request could not be updated: #{inspect(reason)}"

  defp humanize_error({:translation_pull_request_closed, pull_request_number}),
    do:
      "Translation pull request ##{pull_request_number} was closed without merging. Reopen it or start another translation."

  defp humanize_error(:codex_session_token_missing),
    do: "Could not read a local Codex session token for development translation."

  defp humanize_error(reason), do: "Translation failed: #{inspect(reason)}"
end
