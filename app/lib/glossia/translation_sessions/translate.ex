defmodule Glossia.TranslationSessions.Translate do
  @moduledoc """
  Runs repository translation sessions in a sandbox.
  """

  require Logger

  alias Glossia.{Events, Ingestion, TranslationSessions}
  alias Glossia.TranslationSessions.TranslationSession

  @translation_branch_prefix "glossia/translate"

  def run(session_id, opts \\ []) do
    session =
      TranslationSessions.get_session!(session_id)
      |> Glossia.Repo.preload(project: [:account, :github_installation])

    project = session.project
    account = project.account

    do_run(session, project, account, opts)
  end

  defp do_run(%TranslationSession{} = session, project, account, opts) do
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
      publication_target = publication_target(session, project, token)

      case Glossia.Translations.RepositoryRun.run(session, account, repository, locales,
             publication_target: publication_target
           ) do
        {:ok, changes} ->
          result = publication_result(session, changes, publication_target)
          handle_translation_result(session, project, account, result, opts)

        {:error, reason} ->
          fail_translation(session, project, account, reason, opts)
      end
    else
      {:error, reason} ->
        fail_translation(session, project, account, reason, opts)
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

  defp publication_target(session, project, token)
       when not is_nil(project.github_installation) and is_binary(token) and token != "" do
    %{
      node: Node.self(),
      module: __MODULE__,
      context: %{session_id: session.id, token: token}
    }
  end

  defp publication_target(_session, _project, _token), do: nil

  defp publication_result(_session, changes, nil) do
    if changes == [], do: :no_changes, else: :skipped_pull_request
  end

  defp publication_result(session, changes, _publication_target) do
    fresh = TranslationSessions.get_session!(session.id)

    cond do
      is_binary(fresh.pull_request_url) and fresh.pull_request_url != "" ->
        {:published, fresh.pull_request_url}

      changes == [] ->
        :no_changes

      true ->
        {:error, :invalid_github_response}
    end
  end

  @doc false
  def publish_item(
        %{session_id: session_id, token: token},
        %{changes: changes, output_path: output_path, locale: locale}
      )
      when is_list(changes) and is_binary(token) do
    session =
      TranslationSessions.get_session!(session_id)
      |> Glossia.Repo.preload(project: [:account, :github_installation])

    do_publish_item(session, session.project, token, changes, output_path, locale)
  end

  defp do_publish_item(session, project, token, changes, output_path, locale) do
    full_name = project.github_repo_full_name
    default_branch = project.github_repo_default_branch || "main"
    branch_name = session.publication_branch || translation_branch_name(session)
    commit_message = translation_item_commit_message(output_path, locale)

    with {:ok, parent_commit_sha} <-
           publication_parent_sha(full_name, default_branch, session, token),
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
         {:ok, pull_request_url, pull_request_created?} <-
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
             pull_request_url: pull_request_url
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

  defp publication_parent_sha(
         _full_name,
         _default_branch,
         %TranslationSession{publication_commit_sha: sha},
         _token
       )
       when is_binary(sha) and sha != "",
       do: {:ok, sha}

  defp publication_parent_sha(full_name, default_branch, session, token),
    do: base_commit_sha(full_name, default_branch, session, token)

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
         %TranslationSession{pull_request_url: pull_request_url},
         _full_name,
         _default_branch,
         _branch_name,
         _token
       )
       when is_binary(pull_request_url) and pull_request_url != "" do
    {:ok, pull_request_url, false}
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
      {:ok, %{"html_url" => pull_request_url}} when is_binary(pull_request_url) ->
        {:ok, pull_request_url, true}

      {:ok, _response} ->
        {:error, :invalid_github_response}

      {:error, _reason} = error ->
        error
    end
  end

  defp handle_translation_result(
         session,
         project,
         account,
         {:published, _pull_request_url},
         _opts
       ) do
    summary = "Created translation pull request."

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

  defp handle_translation_result(session, project, account, :skipped_pull_request, _opts) do
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

  defp handle_translation_result(session, project, account, :no_changes, _opts) do
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

  defp handle_translation_result(session, _project, _account, {:error, reason}, opts) do
    fail_translation(
      session,
      session.project,
      session.account,
      {:translation_publication_failed, reason},
      opts
    )
  end

  defp fail_translation(session, project, account, reason, opts) do
    error_msg = humanize_error(reason)
    Logger.error("Translation failed for session #{session.id}: #{inspect(reason)}")

    if Keyword.get(opts, :terminal_failure?, true) do
      TranslationSessions.update_session_status(session, "failed", error: error_msg)

      record_translation_event(session, %{
        "event_type" => "error",
        "content" => error_msg,
        "metadata" => %{}
      })

      Events.emit("translation_session.failed", account, nil,
        resource_type: "translation_session",
        resource_id: to_string(session.id),
        resource_path: "/#{account.handle}/#{project.handle}/-/sessions/#{session.id}",
        summary:
          "Translation session failed for #{project.handle}: #{String.slice(error_msg, 0, 200)}"
      )
    else
      Logger.warning(
        "Translation attempt for session #{session.id} will be retried: #{inspect(reason)}"
      )
    end

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

    Glossia translated stale or missing localized content and updated the corresponding `.glossia/` lockfiles.

    ## Why

    #{languages}
    #{commit}

    ## Approach

    The translation harness ran inside a sandbox, used `GLOSSIA.md` to build the translation plan, and let the lockfiles decide which outputs needed work.

    ## Impact

    Reviewers should check the translated copy and keep the lockfile changes with the translated files.

    ## Validation

    The translation command completed successfully inside a sandbox.
    """
  end

  defp translation_item_commit_message(output_path, locale) do
    "feat: translate #{Path.basename(output_path)} to #{locale}"
  end

  defp humanize_error(:translation_harness_failed),
    do: "The translation harness encountered an error and could not complete."

  defp humanize_error(:translation_harness_timeout),
    do: "The translation harness timed out before completing."

  defp humanize_error(:runner_timeout),
    do: "Translation stopped because the isolated runner timed out. Please retry."

  defp humanize_error({:runner_exit, _reason}),
    do: "Translation stopped unexpectedly in the isolated runner. Please retry."

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

  defp humanize_error(:codex_session_token_missing),
    do: "Could not read a local Codex session token for development translation."

  defp humanize_error(reason), do: "Translation failed: #{inspect(reason)}"
end
