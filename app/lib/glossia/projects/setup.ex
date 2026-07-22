defmodule Glossia.Projects.Setup do
  @moduledoc """
  Runs the project setup process: creates a sandbox, starts the setup harness,
  waits for completion, and optionally opens a pull request with the generated
  localization setup changes.

  Called by `Glossia.Projects.SetupWorker` for durable lifecycle management.
  Projects remain provisional until setup completes and are discarded after a
  terminal setup failure.
  """

  require Logger

  alias Glossia.{Events, Ingestion, Projects, Sandboxes}
  alias Glossia.Models.ModelIdentifier
  alias Glossia.Translations.Credentials

  @change_manifest_filename "glossia-setup-changes.json"
  @context_file_names ["GLOSSIA.md"]
  @setup_branch_name "glossia/setup-localization"

  @doc """
  Runs setup for the given project ID. Broadcasts status updates via PubSub
  so the LiveView can reflect progress in real time.

  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  def run(project_id, opts \\ []) do
    project =
      Glossia.Repo.get!(Glossia.Accounts.Project, project_id)
      |> Glossia.Repo.preload([:account, :github_installation])

    account = project.account

    project
    |> do_run(account, opts)
    |> discard_failed_project(project)
  rescue
    exception ->
      error_msg = Exception.message(exception)
      Logger.error("Setup crashed for project #{project_id}: #{error_msg}")

      project =
        case Glossia.Repo.get(Glossia.Accounts.Project, project_id) do
          nil -> nil
          p -> p
        end

      if project do
        case Projects.update_project_setup_status(project, "failed", error_msg) do
          {:ok, failed_project} ->
            discard_failed_project({:error, error_msg}, failed_project)

          {:error, _reason} ->
            :ok
        end
      end

      {:error, error_msg}
  end

  defp do_run(project, account, opts) do
    Projects.update_project_setup_status(project, "running")
    Projects.broadcast_setup_status(project, "running")

    Events.emit("project.setup_started", account, nil,
      resource_type: "project",
      resource_id: to_string(project.id),
      resource_path: "/#{account.handle}/#{project.handle}",
      summary: "Setup started for #{project.handle}"
    )

    sandbox = Keyword.get(opts, :sandbox_adapter, Glossia.Sandbox.adapter())

    with {:ok, harness_config} <- setup_harness_config(account, project),
         {:ok, token} <- get_clone_token(project),
         {:ok, sandbox_record} <- ensure_sandbox(project, account, sandbox) do
      run_in_sandbox(project, account, sandbox, sandbox_record, token, harness_config)
    else
      {:error, :setup_already_running} = error ->
        error

      {:error, reason} ->
        fail_setup(project, account, reason)
    end
  end

  defp run_in_sandbox(project, account, sandbox, sandbox_record, token, harness_config) do
    sandbox_id = to_string(sandbox_record.id)

    with {:ok, repo_path} <- sandbox.repo_path(sandbox_id),
         {:ok, _status} <-
           start_agent_and_wait(
             sandbox,
             sandbox_id,
             project,
             token,
             harness_config
           ) do
      result = maybe_create_pr(project, sandbox, sandbox_id, repo_path)
      outcome = handle_setup_result(project, account, result, sandbox_id)

      Sandboxes.destroy_sandbox(sandbox_record, adapter: sandbox, reason: "setup_completed")
      Projects.replace_project_sandbox_id(project, sandbox_id, nil)

      outcome
    else
      {:error, reason} ->
        result = fail_setup(project, account, reason, sandbox_id)
        cleanup_project_sandbox(project, sandbox, "setup_failed", sandbox_id)
        result
    end
  end

  defp handle_setup_result(project, account, {:ok, pull_request}, sandbox_id) do
    with {:ok, _project} <-
           Projects.complete_project_setup(project, sandbox_id, pull_request) do
      record_setup_event(project, "pr_created", pull_request.url, %{
        "label" => "pull_request",
        "repo" => project.github_repo_full_name || "",
        "number" => pull_request.number
      })

      Projects.broadcast_setup_status(project, "completed")

      Events.emit("project.setup_completed", account, nil,
        resource_type: "project",
        resource_id: to_string(project.id),
        resource_path: "/#{account.handle}/#{project.handle}",
        summary: "Setup completed for #{project.handle}, pull request: #{pull_request.url}"
      )
    end

    :ok
  end

  defp handle_setup_result(project, account, :skipped_pr, sandbox_id) do
    Logger.info("Setup completed for project #{project.id}, PR creation skipped (no GitHub App)")

    with {:ok, _project} <-
           Projects.update_project_setup_status_if_sandbox_id(project, sandbox_id, "completed") do
      Projects.broadcast_setup_status(project, "completed")

      Events.emit("project.setup_completed", account, nil,
        resource_type: "project",
        resource_id: to_string(project.id),
        resource_path: "/#{account.handle}/#{project.handle}",
        summary: "Setup completed for #{project.handle} (PR skipped, no GitHub App)"
      )
    end

    :ok
  end

  defp handle_setup_result(project, account, {:error, :setup_context_missing}, sandbox_id) do
    error_msg = "Setup finished without generating GLOSSIA.md, so no pull request was created."

    Logger.error("Setup failed for project #{project.id}: #{error_msg}")

    with {:ok, _project} <-
           Projects.update_project_setup_status_if_sandbox_id(
             project,
             sandbox_id,
             "failed",
             error_msg
           ) do
      Events.emit("project.setup_failed", account, nil,
        resource_type: "project",
        resource_id: to_string(project.id),
        resource_path: "/#{account.handle}/#{project.handle}",
        summary: "Setup failed for #{project.handle}: #{error_msg}"
      )
    end

    {:error, :setup_context_missing}
  end

  defp handle_setup_result(project, _account, {:error, reason}, sandbox_id) do
    error_msg = humanize_error(reason)
    Logger.error("Setup publication failed for project #{project.id}: #{inspect(reason)}")

    _ =
      Projects.update_project_setup_status_if_sandbox_id(
        project,
        sandbox_id,
        "failed",
        error_msg
      )

    {:error, {:setup_publication_failed, reason}}
  end

  defp fail_setup(project, account, reason) do
    error_msg = humanize_error(reason)
    Logger.error("Setup failed for project #{project.id}: #{inspect(reason)}")
    Projects.update_project_setup_status(project, "failed", error_msg)

    Events.emit("project.setup_failed", account, nil,
      resource_type: "project",
      resource_id: to_string(project.id),
      resource_path: "/#{account.handle}/#{project.handle}",
      summary: "Setup failed for #{project.handle}: #{String.slice(error_msg, 0, 200)}"
    )

    {:error, reason}
  end

  defp fail_setup(project, account, reason, sandbox_id) do
    error_msg = humanize_error(reason)
    Logger.error("Setup failed for project #{project.id}: #{inspect(reason)}")

    with {:ok, _project} <-
           Projects.update_project_setup_status_if_sandbox_id(
             project,
             sandbox_id,
             "failed",
             error_msg
           ) do
      Events.emit("project.setup_failed", account, nil,
        resource_type: "project",
        resource_id: to_string(project.id),
        resource_path: "/#{account.handle}/#{project.handle}",
        summary: "Setup failed for #{project.handle}: #{String.slice(error_msg, 0, 200)}"
      )
    end

    {:error, reason}
  end

  defp discard_failed_project({:error, :setup_already_running} = error, _project), do: error

  defp discard_failed_project({:error, reason} = error, project) do
    case Projects.discard_failed_project_setup(project) do
      {:ok, discarded_project} ->
        setup_error = discarded_project.setup_error || humanize_error(reason)
        Projects.broadcast_setup_failure(discarded_project, setup_error)

      {:error, :setup_not_failed} ->
        :ok
    end

    error
  end

  defp discard_failed_project(result, _project), do: result

  defp get_clone_token(project) do
    installation = project.github_installation

    if local_clone_url(project) || is_nil(installation) do
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

  defp ensure_sandbox(project, account, sandbox) do
    case project.setup_sandbox_id do
      nil ->
        create_sandbox(project, account, sandbox)

      existing_id ->
        case Sandboxes.get_sandbox_by_id(existing_id) do
          nil ->
            Logger.info(
              "Unknown sandbox #{existing_id} for project #{project.id}, creating new one"
            )

            with :ok <- delete_missing_sandbox_id(sandbox, existing_id),
                 {:ok, _project} <- Projects.replace_project_sandbox_id(project, existing_id, nil) do
              create_sandbox(project, account, sandbox)
            end

          sandbox_record ->
            cond do
              sandbox_record.account_id != account.id or sandbox_record.project_id != project.id ->
                Logger.warning(
                  "Ignoring sandbox #{existing_id} for project #{project.id}: ownership mismatch"
                )

                with {:ok, _project} <-
                       Projects.replace_project_sandbox_id(project, existing_id, nil) do
                  create_sandbox(project, account, sandbox)
                end

              sandbox_alive?(sandbox, existing_id) ->
                Logger.info("Resuming sandbox #{existing_id} for project #{project.id}")
                {:ok, sandbox_record}

              true ->
                Logger.info(
                  "Stale sandbox #{existing_id} for project #{project.id}, creating new one"
                )

                with {:ok, _terminated} <-
                       Sandboxes.destroy_sandbox(sandbox_record,
                         adapter: sandbox,
                         reason: "stale"
                       ),
                     {:ok, _project} <-
                       Projects.replace_project_sandbox_id(project, existing_id, nil) do
                  create_sandbox(project, account, sandbox)
                end
            end
        end
    end
  end

  defp create_sandbox(project, account, sandbox) do
    attrs = %{
      purpose: "project_setup",
      labels: %{
        "project_id" => to_string(project.id),
        "purpose" => "project_setup"
      }
    }

    case Sandboxes.create_sandbox(account, project, attrs, adapter: sandbox) do
      {:ok, sandbox_record} ->
        sandbox_id = to_string(sandbox_record.id)

        case Projects.replace_project_sandbox_id(project, nil, sandbox_id) do
          {:ok, _project} ->
            {:ok, sandbox_record}

          {:error, :setup_sandbox_id_changed} ->
            Sandboxes.destroy_sandbox(sandbox_record,
              adapter: sandbox,
              reason: "setup_superseded"
            )

            {:error, :setup_already_running}
        end

      {:error, _} = err ->
        err
    end
  end

  defp sandbox_alive?(sandbox, sandbox_id) do
    case sandbox.execute(sandbox_id, "echo ok") do
      {:ok, %{"exitCode" => 0}} -> true
      {:error, :command_already_running} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  defp start_agent_and_wait(
         sandbox,
         sandbox_id,
         project,
         github_token,
         harness_config
       ) do
    timeout_ms = setup_harness_timeout_ms()

    with {:ok, _pid} <-
           Glossia.Sandbox.start_agent_session(sandbox, sandbox_id, self(),
             project_id: project.id,
             repository: %{
               full_name: project.github_repo_full_name,
               default_branch: project.github_repo_default_branch || "main",
               token: github_token,
               clone_url: local_clone_url(project)
             },
             target_languages: project.setup_target_languages || [],
             harness: harness_config,
             timeout_ms: timeout_ms
           ) do
      wait_for_completion(project, timeout_ms + 60_000)
    end
  end

  defp wait_for_completion(project, timeout_ms) do
    receive do
      {:agent_event, event} ->
        record_agent_event(project, event)
        wait_for_completion(project, timeout_ms)

      {:agent_done, :completed} ->
        Logger.info("Setup harness completed for project #{project.id}")
        {:ok, :completed}

      {:agent_done, :failed} ->
        Logger.warning("Setup harness failed for project #{project.id}")
        {:error, :setup_harness_failed}
    after
      timeout_ms ->
        Logger.warning("Setup harness timed out for project #{project.id}")
        {:error, :setup_harness_timeout}
    end
  end

  defp setup_harness_timeout_ms do
    :glossia
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:harness_timeout_ms, 660_000)
  end

  defp record_agent_event(project, %{"event_type" => event_type} = event)
       when is_binary(event_type) do
    content = Map.get(event, "content", "")
    metadata = Map.get(event, "metadata", %{})
    record_setup_event(project, event_type, content, metadata)
  end

  defp record_agent_event(_project, _event), do: :ok

  defp maybe_create_pr(project, sandbox, sandbox_id, repo_path) do
    with {:ok, changes} <-
           download_setup_changes(
             sandbox,
             sandbox_id,
             repo_path,
             project.setup_target_languages || []
           ) do
      create_pr(project, changes)
    end
  end

  defp create_pr(project, changes) do
    installation = project.github_installation

    if local_clone_url(project) || is_nil(installation) do
      Logger.info(
        "No publishable GitHub installation linked, skipping pull request creation for project #{project.id}"
      )

      :skipped_pr
    else
      case Glossia.Github.App.installation_token(installation.github_installation_id) do
        {:ok, token} ->
          do_create_pr(project, token, changes)

        {:error, :not_configured} ->
          Logger.info(
            "GitHub App not configured, skipping pull request creation for project #{project.id}"
          )

          :skipped_pr

        {:error, reason} ->
          {:error, {:github_token_failed, reason}}
      end
    end
  end

  defp do_create_pr(project, token, changes) do
    full_name = project.github_repo_full_name
    default_branch = project.github_repo_default_branch || "main"
    branch_name = @setup_branch_name

    with {:ok, ref_data} <-
           Glossia.Github.Client.get_ref(full_name, "heads/#{default_branch}", token),
         base_commit_sha when is_binary(base_commit_sha) <- get_in(ref_data, ["object", "sha"]),
         {:ok, base_commit} <-
           Glossia.Github.Client.get_commit(full_name, base_commit_sha, token),
         base_tree_sha when is_binary(base_tree_sha) <- get_in(base_commit, ["tree", "sha"]),
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
               message: "feat: set up Glossia localization",
               tree: tree_sha,
               parents: [base_commit_sha]
             },
             token
           ),
         commit_sha when is_binary(commit_sha) <- commit["sha"],
         :ok <- create_or_update_branch(full_name, branch_name, commit_sha, token),
         {:ok, %{"number" => pr_number, "html_url" => pr_url} = pr}
         when is_integer(pr_number) and is_binary(pr_url) and pr_url != "" <-
           Glossia.Github.Client.create_pull_request(
             full_name,
             %{
               title: "feat: set up Glossia localization",
               body: pull_request_body(project),
               head: branch_name,
               base: default_branch
             },
             token
           ) do
      {:ok,
       %{
         number: pr_number,
         url: pr_url,
         state: pr["state"] || "open",
         merged_at: nil
       }}
    else
      {:error, _reason} = error -> error
      _invalid_response -> {:error, :invalid_github_response}
    end
  end

  defp download_setup_changes(sandbox, sandbox_id, repo_path, target_languages) do
    manifest_path = Path.join(Path.dirname(repo_path), @change_manifest_filename)

    with {:ok, manifest} <- download_manifest(sandbox, sandbox_id, manifest_path),
         {:ok, decoded} <- decode_manifest(manifest),
         {:ok, files} <- parse_changed_files(decoded),
         :ok <- validate_changed_files(files),
         {:ok, changes} <- download_changed_file_contents(sandbox, sandbox_id, repo_path, files),
         :ok <- validate_target_catalogs(changes, target_languages) do
      {:ok, changes}
    end
  end

  defp download_manifest(sandbox, sandbox_id, manifest_path) do
    case sandbox.download_file(sandbox_id, manifest_path) do
      {:ok, manifest} when is_binary(manifest) and manifest != "" ->
        {:ok, manifest}

      {:ok, _empty} ->
        {:error, :setup_change_manifest_empty}

      {:error, _reason} ->
        {:error, :setup_change_manifest_missing}
    end
  end

  defp decode_manifest(manifest) do
    case JSON.decode(manifest) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, _reason} -> {:error, :setup_change_manifest_invalid}
    end
  end

  defp parse_changed_files(%{"version" => 1, "files" => files}) when is_list(files) do
    files
    |> Enum.reduce_while({:ok, []}, fn file, {:ok, acc} ->
      case parse_changed_file(file) do
        {:ok, parsed} -> {:cont, {:ok, [parsed | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, parsed} ->
        parsed =
          parsed
          |> Enum.reverse()
          |> Enum.uniq_by(& &1.path)

        {:ok, parsed}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_changed_files(_decoded), do: {:error, :setup_change_manifest_invalid}

  defp parse_changed_file(%{"path" => path, "status" => status})
       when status in ["added", "modified", "deleted"] do
    with :ok <- validate_changed_file_path(path) do
      {:ok, %{path: path, status: status}}
    end
  end

  defp parse_changed_file(_file), do: {:error, :setup_change_manifest_invalid}

  defp validate_changed_file_path(path) when is_binary(path) do
    cond do
      String.trim(path) == "" ->
        {:error, :setup_change_manifest_invalid}

      Path.type(path) != :relative ->
        {:error, :setup_change_manifest_invalid}

      path in ["opencode.json", @change_manifest_filename] ->
        {:error, :setup_change_manifest_invalid}

      String.starts_with?(path, "../") or String.contains?(path, "/../") ->
        {:error, :setup_change_manifest_invalid}

      String.starts_with?(path, ".git/") or String.starts_with?(path, ".opencode/") or
          String.starts_with?(path, ".glossia/") ->
        {:error, :setup_change_manifest_invalid}

      String.starts_with?(path, "node_modules/") ->
        {:error, :setup_change_manifest_invalid}

      true ->
        :ok
    end
  end

  defp validate_changed_file_path(_path), do: {:error, :setup_change_manifest_invalid}

  defp validate_changed_files([]), do: {:error, :setup_changes_empty}

  defp validate_changed_files(files) do
    if Enum.any?(files, &context_file_path?/1) do
      :ok
    else
      {:error, :setup_context_missing}
    end
  end

  defp context_file_path?(%{path: path}) do
    Enum.any?(@context_file_names, fn name ->
      path == name or String.ends_with?(path, "/" <> name)
    end)
  end

  defp download_changed_file_contents(sandbox, sandbox_id, repo_path, files) do
    files
    |> Enum.reduce_while({:ok, []}, fn
      %{status: "deleted"} = file, {:ok, acc} ->
        {:cont, {:ok, [Map.put(file, :content, nil) | acc]}}

      file, {:ok, acc} ->
        path = Path.join(repo_path, file.path)

        case sandbox.download_file(sandbox_id, path) do
          {:ok, content} when is_binary(content) ->
            {:cont, {:ok, [Map.put(file, :content, content) | acc]}}

          {:error, _reason} ->
            {:halt, {:error, {:setup_changed_file_missing, file.path}}}
        end
    end)
    |> case do
      {:ok, changes} -> {:ok, Enum.reverse(changes)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_target_catalogs(changes, target_languages) do
    empty_catalog =
      Enum.find(changes, fn change ->
        published_target_portable_object_catalog?(change, target_languages) and
          not portable_object_catalog_has_messages?(change.content)
      end)

    case empty_catalog do
      nil -> :ok
      %{path: path} -> {:error, {:setup_target_catalog_empty, path}}
    end
  end

  defp published_target_portable_object_catalog?(
         %{path: path, status: status, content: content},
         target_languages
       )
       when status in ["added", "modified"] and is_binary(content) do
    path_parts = Path.split(path)
    basename = Path.basename(path, ".po")

    Path.extname(path) == ".po" and
      Enum.any?(target_languages, fn language ->
        language in path_parts or language == basename
      end)
  end

  defp published_target_portable_object_catalog?(_change, _target_languages), do: false

  defp portable_object_catalog_has_messages?(content) do
    content
    |> String.split(~r/\R{2,}/)
    |> Enum.any?(&portable_object_entry_has_message?/1)
  end

  defp portable_object_entry_has_message?(entry) do
    lines = String.split(entry, ~r/\R/)
    message_index = Enum.find_index(lines, &String.starts_with?(&1, "msgid "))

    if is_integer(message_index) do
      message_lines =
        lines
        |> Enum.drop(message_index)
        |> Enum.take_while(&(not String.starts_with?(&1, "msgstr")))

      Enum.any?(message_lines, &portable_object_message_line_has_content?/1)
    else
      false
    end
  end

  defp portable_object_message_line_has_content?(line) do
    line = String.trim_leading(line)

    case Regex.run(~r/^(?:msgid\s+)?"(.*)"$/, line, capture: :all_but_first) do
      [value] -> value != ""
      _no_message -> false
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

  defp create_or_update_branch(full_name, branch_name, sha, token) do
    case Glossia.Github.Client.create_branch(full_name, branch_name, sha, token) do
      {:ok, _} ->
        :ok

      {:error, {:api_error, 422, _body}} ->
        case Glossia.Github.Client.update_ref(full_name, "heads/#{branch_name}", sha, token,
               force: true
             ) do
          {:ok, _} -> :ok
          {:error, _reason} = error -> error
        end

      {:error, _reason} = error ->
        error
    end
  end

  defp pull_request_body(project) do
    language_list =
      case project.setup_target_languages || [] do
        [] -> "Target languages follow the repository's existing localization conventions."
        languages -> "Target languages: `" <> Enum.join(languages, "`, `") <> "`."
      end

    """
    ## What changed

    Adds the initial Glossia localization configuration and repository context.

    #{language_list}

    ## Why

    Glossia needs repository-specific language settings, source paths, and translation context before it can prepare localized content.

    ## Approach

    The proposed setup follows the repository's existing localization conventions and preserves source-language behavior as the fallback.

    ## Impact

    After this pull request is merged, Glossia can use the configuration as the baseline for future translation runs. Translated content remains a separate reviewable change.
    """
  end

  defp record_setup_event(project, event_type, content, metadata) do
    sequence = next_setup_event_sequence(project)
    metadata_json = encode_event_metadata(metadata)

    Ingestion.record_setup_event(project.id, sequence, event_type, content || "", metadata_json)

    Projects.broadcast_setup_event(project, %{
      sequence: sequence,
      event_type: event_type,
      content: content || "",
      metadata: metadata_json
    })
  end

  defp encode_event_metadata(metadata) when is_binary(metadata), do: metadata
  defp encode_event_metadata(metadata), do: JSON.encode!(metadata || %{})

  defp next_setup_event_sequence(project) do
    key = {__MODULE__, :setup_event_sequence, project.id}
    sequence = (Process.get(key) || Ingestion.max_setup_event_sequence(project.id)) + 1
    Process.put(key, sequence)
    sequence
  end

  defp humanize_error(:setup_model_not_configured),
    do:
      "The localization setup model is not configured. Configure a default model for this account before retrying setup."

  defp humanize_error(:setup_session_not_supported),
    do: "The selected development model session cannot run the setup harness."

  defp humanize_error(:codex_session_not_available),
    do: "The local Codex session is unavailable or expired. Sign in again before retrying setup."

  defp humanize_error(:claude_session_not_available),
    do: "The local Claude session is unavailable or expired. Sign in again before retrying setup."

  defp humanize_error(:setup_session_requires_local_repository),
    do: "Local development sessions can only set up repositories seeded on this machine."

  defp humanize_error(:setup_harness_failed),
    do: "The setup harness encountered an error and could not complete."

  defp humanize_error(:setup_harness_timeout),
    do: "The setup harness timed out before completing."

  defp humanize_error({:github_token_failed, _}),
    do: "Could not authenticate with GitHub. Check the app installation."

  defp humanize_error(:sandboxes_disabled),
    do: "Sandbox workflow execution is disabled."

  defp humanize_error(:sandbox_quota_exceeded),
    do: "The account has reached its active sandbox limit."

  defp humanize_error(:sandbox_start_timeout),
    do: "The setup environment took too long to start. Please retry setup."

  defp humanize_error({:sandbox_start_timeout, _reason}),
    do: "The setup environment took too long to start. Please retry setup."

  defp humanize_error(:setup_already_running),
    do: "Project setup is already running."

  defp humanize_error(:setup_sandbox_id_changed),
    do: "Project setup changed while this run was starting."

  defp humanize_error(:setup_change_manifest_missing),
    do: "The setup harness did not report the files it changed."

  defp humanize_error(:setup_change_manifest_empty),
    do: "The setup harness reported an empty changed-file manifest."

  defp humanize_error(:setup_change_manifest_invalid),
    do: "The setup harness reported an invalid changed-file manifest."

  defp humanize_error(:setup_changes_empty),
    do: "The setup harness completed without changing repository files."

  defp humanize_error(:setup_context_missing),
    do: "The setup harness completed without creating or updating a Glossia context file."

  defp humanize_error({:setup_target_catalog_empty, path}),
    do:
      "The setup assistant created #{path} without source messages. Target catalogs must include extracted source messages or be omitted until translation."

  defp humanize_error({:setup_changed_file_missing, path}),
    do: "The setup harness reported #{path}, but that file could not be read from the sandbox."

  defp humanize_error(:invalid_github_response),
    do: "GitHub returned an unexpected response while creating the setup pull request."

  defp humanize_error({:setup_publication_failed, reason}), do: humanize_error(reason)

  defp humanize_error(reason) when is_binary(reason), do: reason
  defp humanize_error(reason), do: inspect(reason)

  defp setup_harness_config(account, project) do
    config = Application.get_env(:glossia, __MODULE__, [])

    {account_credential, credential_error} =
      case Credentials.setup_harness_credential(account) do
        {:ok, credential} -> {credential, nil}
        {:error, {:model_not_found, _handle}} -> {nil, :setup_model_not_configured}
        {:error, reason} -> {nil, reason}
      end

    minimax_api_key = Keyword.get(config, :minimax_api_key)
    configured_model = Keyword.get(config, :harness_model) || Keyword.get(config, :model)

    model =
      cond do
        account_credential ->
          ModelIdentifier.normalize(account_credential.model)

        is_binary(configured_model) and configured_model != "" and
          is_binary(minimax_api_key) and minimax_api_key != "" and
            not String.contains?(configured_model, ["/", ":"]) ->
          "minimax/#{configured_model}"

        is_binary(configured_model) and configured_model != "" ->
          ModelIdentifier.normalize(configured_model)

        is_binary(minimax_api_key) and minimax_api_key != "" ->
          "minimax/MiniMax-M2.5"

        true ->
          nil
      end

    opencode_config =
      if account_credential,
        do: account_credential.opencode_config,
        else: setup_opencode_config(config, minimax_api_key, model)

    cond do
      not harness_model_configured?(model, opencode_config) ->
        {:error, credential_error || :setup_model_not_configured}

      account_credential && account_credential.source in [:codex_session, :claude_session] &&
          is_nil(local_clone_url(project)) ->
        {:error, :setup_session_requires_local_repository}

      true ->
        harness_name =
          if(account_credential,
            do: Map.get(account_credential, :harness),
            else: nil
          ) || to_string(Keyword.get(config, :harness, "opencode"))

        harness_command =
          if(account_credential,
            do: Map.get(account_credential, :command),
            else: nil
          ) || Keyword.get(config, :harness_command, "opencode")

        {:ok,
         %{
           name: harness_name,
           command: harness_command,
           model: model,
           agent: Keyword.get(config, :harness_agent),
           pure: Keyword.get(config, :harness_pure, true),
           env: normalize_harness_env(Keyword.get(config, :harness_env, %{})),
           opencode_config: opencode_config,
           opencode_auth: if(account_credential, do: account_credential.opencode_auth, else: %{}),
           codex_auth:
             if(account_credential, do: Map.get(account_credential, :codex_auth, %{}), else: %{}),
           claude_auth:
             if(account_credential, do: Map.get(account_credential, :claude_auth, %{}), else: %{}),
           context: setup_harness_context(config)
         }}
    end
  end

  defp local_clone_url(project) do
    config = Application.get_env(:glossia, __MODULE__, [])
    host_dir = Keyword.get(config, :local_remotes_dir)
    guest_dir = Keyword.get(config, :local_remotes_guest_dir)
    full_name = project.github_repo_full_name

    if is_binary(host_dir) and is_binary(guest_dir) and is_binary(full_name) and
         File.dir?(Path.join(host_dir, full_name)) do
      "file://" <> Path.join(guest_dir, full_name)
    end
  end

  defp harness_model_configured?(model, opencode_config) do
    has_model?(model) or has_model?(is_map(opencode_config) && opencode_config["model"])
  end

  defp has_model?(value), do: is_binary(value) and value != ""

  defp setup_opencode_config(config, minimax_api_key, model) do
    configured = Keyword.get(config, :opencode_config)

    cond do
      is_map(configured) and map_size(configured) > 0 ->
        configured

      is_binary(configured) and configured != "" ->
        case JSON.decode(configured) do
          {:ok, decoded} when is_map(decoded) -> decoded
          _ -> %{}
        end

      is_binary(minimax_api_key) and minimax_api_key != "" ->
        %{
          "model" => model || "minimax/MiniMax-M2.5",
          "provider" => %{
            "minimax" => %{
              "npm" => "@ai-sdk/anthropic",
              "name" => "MiniMax",
              "options" => %{
                "baseURL" => "https://api.minimax.io/anthropic/v1",
                "apiKey" => minimax_api_key
              },
              "models" => %{
                "MiniMax-M2.5" => %{
                  "name" => "MiniMax-M2.5",
                  "limit" => %{
                    "context" => 200_000,
                    "output" => 131_072
                  }
                }
              }
            }
          }
        }

      is_binary(model) and model != "" ->
        %{"model" => model}

      true ->
        %{}
    end
  end

  defp setup_harness_context(config) do
    context_path = Keyword.get(config, :harness_context_path)

    cond do
      not is_binary(context_path) or context_path == "" ->
        nil

      not File.exists?(context_path) ->
        nil

      true ->
        content = File.read!(context_path)
        binary_part(content, 0, min(byte_size(content), 128_000))
    end
  end

  defp normalize_harness_env(env) when is_map(env) do
    Map.new(env, fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp normalize_harness_env(env) when is_list(env) do
    Map.new(env, fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp normalize_harness_env(_env), do: %{}

  defp cleanup_project_sandbox(project, sandbox, reason, sandbox_id) when is_binary(sandbox_id) do
    cleanup_result =
      if sandbox_record = Sandboxes.get_sandbox_by_id(sandbox_id) do
        Sandboxes.destroy_sandbox(sandbox_record, adapter: sandbox, reason: reason)
      else
        delete_missing_sandbox_id(sandbox, sandbox_id)
      end

    case cleanup_result do
      {:error, _reason} ->
        :ok

      _ok ->
        case Projects.replace_project_sandbox_id(project, sandbox_id, nil) do
          {:ok, _project} -> :ok
          {:error, :setup_sandbox_id_changed} -> :ok
        end
    end
  end

  defp delete_missing_sandbox_id(sandbox, sandbox_id) do
    case sandbox.delete(to_string(sandbox_id)) do
      :ok -> :ok
      {:error, :not_found} -> :ok
      {:error, reason} -> {:error, {:sandbox_delete_failed, reason}}
    end
  end
end
