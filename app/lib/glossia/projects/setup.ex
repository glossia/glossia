defmodule Glossia.Projects.Setup do
  @moduledoc """
  Runs the project setup process: creates a sandbox, starts the agent,
  waits for completion, and optionally opens a PR with the generated
  L10N.md file.

  Called by `Glossia.Projects.SetupWorker` (Oban) for retry semantics
  and lifecycle management.
  """

  require Logger

  alias Glossia.{Events, Ingestion, Projects, Sandboxes}

  @doc """
  Runs setup for the given project ID. Broadcasts status updates via PubSub
  so the LiveView can reflect progress in real time.

  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  def run(project_id) do
    project =
      Glossia.Repo.get!(Glossia.Accounts.Project, project_id)
      |> Glossia.Repo.preload([:account, :github_installation])

    account = project.account
    do_run(project, account)
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
        Projects.update_project_setup_status(project, "failed", error_msg)
        Projects.broadcast_setup_status(project, "failed")
      end

      {:error, error_msg}
  end

  defp do_run(project, account) do
    Projects.update_project_setup_status(project, "running")
    Projects.broadcast_setup_status(project, "running")

    Events.emit("project.setup_started", account, nil,
      resource_type: "project",
      resource_id: to_string(project.id),
      resource_path: "/#{account.handle}/#{project.handle}",
      summary: "Setup started for #{project.handle}"
    )

    sandbox = Glossia.Sandbox.adapter()

    with {:ok, token} <- get_clone_token(project),
         {:ok, sandbox_record} <- ensure_sandbox(project, account, sandbox) do
      run_in_sandbox(project, account, sandbox, sandbox_record, token)
    else
      {:error, :setup_already_running} = error ->
        error

      {:error, reason} ->
        fail_setup(project, account, reason)
    end
  end

  defp run_in_sandbox(project, account, sandbox, sandbox_record, token) do
    sandbox_id = to_string(sandbox_record.id)

    with {:ok, repo_path} <- sandbox.repo_path(sandbox_id),
         {:ok, model_config} <- setup_model_config(),
         {:ok, _status} <-
           start_agent_and_wait(sandbox, sandbox_id, project, token, repo_path, model_config) do
      result = maybe_create_pr(project, sandbox, sandbox_id, repo_path)
      outcome = handle_setup_result(project, account, result, sandbox_id)

      Sandboxes.destroy_sandbox(sandbox_record, adapter: sandbox, reason: "setup_completed")
      Projects.replace_project_sandbox_id(project, sandbox_id, nil)

      outcome
    else
      {:error, reason} ->
        cleanup_project_sandbox(project, sandbox, "setup_failed", sandbox_id)
        fail_setup(project, account, reason, sandbox_id)
    end
  end

  defp handle_setup_result(project, account, {:ok, pr_url}, sandbox_id) do
    with {:ok, _project} <-
           Projects.update_project_setup_status_if_sandbox_id(project, sandbox_id, "completed") do
      record_setup_event(project, "pr_created", pr_url, %{
        "label" => "pull_request",
        "repo" => project.github_repo_full_name || ""
      })

      Projects.broadcast_setup_status(project, "completed")

      Events.emit("project.setup_completed", account, nil,
        resource_type: "project",
        resource_id: to_string(project.id),
        resource_path: "/#{account.handle}/#{project.handle}",
        summary: "Setup completed for #{project.handle}, PR: #{pr_url}"
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

  defp handle_setup_result(project, account, :no_l10n_md, sandbox_id) do
    error_msg = "Setup finished without generating L10N.md, so no pull request was created."

    Logger.error("Setup failed for project #{project.id}: #{error_msg}")

    with {:ok, _project} <-
           Projects.update_project_setup_status_if_sandbox_id(
             project,
             sandbox_id,
             "failed",
             error_msg
           ) do
      Projects.broadcast_setup_status(project, "failed")

      Events.emit("project.setup_failed", account, nil,
        resource_type: "project",
        resource_id: to_string(project.id),
        resource_path: "/#{account.handle}/#{project.handle}",
        summary: "Setup failed for #{project.handle}: #{error_msg}"
      )
    end

    {:error, :l10n_md_missing}
  end

  defp handle_setup_result(project, _account, {:error, reason}, sandbox_id) do
    error_msg = humanize_error(reason)
    Logger.error("PR creation failed for project #{project.id}: #{inspect(reason)}")

    with {:ok, _project} <-
           Projects.update_project_setup_status_if_sandbox_id(
             project,
             sandbox_id,
             "failed",
             error_msg
           ) do
      Projects.broadcast_setup_status(project, "failed")
    end

    {:error, {:pr_creation_failed, reason}}
  end

  defp fail_setup(project, account, reason) do
    error_msg = humanize_error(reason)
    Logger.error("Setup failed for project #{project.id}: #{inspect(reason)}")
    Projects.update_project_setup_status(project, "failed", error_msg)
    Projects.broadcast_setup_status(project, "failed")

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
      Projects.broadcast_setup_status(project, "failed")

      Events.emit("project.setup_failed", account, nil,
        resource_type: "project",
        resource_id: to_string(project.id),
        resource_path: "/#{account.handle}/#{project.handle}",
        summary: "Setup failed for #{project.handle}: #{String.slice(error_msg, 0, 200)}"
      )
    end

    {:error, reason}
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

  defp start_agent_and_wait(sandbox, sandbox_id, project, github_token, repo_path, model_config) do
    session_token =
      Phoenix.Token.sign(
        GlossiaWeb.Endpoint,
        "agent_session",
        project.id
      )

    server_url = GlossiaWeb.Endpoint.url()

    config_json =
      JSON.encode!(%{
        github_repo_full_name: project.github_repo_full_name,
        github_repo_default_branch: project.github_repo_default_branch || "main",
        github_token: github_token,
        repo_path: repo_path,
        target_languages: project.setup_target_languages || [],
        minimax_api_key: model_config.minimax_api_key,
        model: model_config.model
      })

    with {:ok, _pid} <-
           Glossia.Sandbox.start_agent_session(sandbox, sandbox_id, self(),
             server_url: server_url,
             session_token: session_token,
             project_id: project.id,
             config_json: config_json
           ) do
      wait_for_completion(project)
    end
  end

  defp wait_for_completion(project) do
    receive do
      {:agent_done, :completed} ->
        Logger.info("Agent session completed for project #{project.id}")
        {:ok, :completed}

      {:agent_done, :failed} ->
        Logger.warning("Agent session failed for project #{project.id}")
        {:error, :agent_session_failed}
    after
      660_000 ->
        Logger.warning("Agent session timed out for project #{project.id}")
        {:error, :agent_timeout}
    end
  end

  defp maybe_create_pr(project, sandbox, sandbox_id, repo_path) do
    case sandbox.download_file(sandbox_id, Path.join(repo_path, "L10N.md")) do
      {:ok, l10n_md} when is_binary(l10n_md) and l10n_md != "" ->
        create_pr(project, l10n_md)

      _ ->
        :no_l10n_md
    end
  end

  defp create_pr(project, l10n_md) do
    installation = project.github_installation

    if is_nil(installation) do
      Logger.info("No GitHub installation linked, skipping PR creation for project #{project.id}")

      :skipped_pr
    else
      case Glossia.Github.App.installation_token(installation.github_installation_id) do
        {:ok, token} ->
          do_create_pr(project, token, l10n_md)

        {:error, :not_configured} ->
          Logger.info("GitHub App not configured, skipping PR creation for project #{project.id}")

          :skipped_pr

        {:error, reason} ->
          {:error, {:github_token_failed, reason}}
      end
    end
  end

  defp do_create_pr(project, token, l10n_md) do
    full_name = project.github_repo_full_name
    default_branch = project.github_repo_default_branch || "main"
    branch_name = "glossia/setup-localization"

    with {:ok, ref_data} <-
           Glossia.Github.Client.get_ref(full_name, "heads/#{default_branch}", token),
         sha = ref_data["object"]["sha"],
         {:ok, _} <-
           Glossia.Github.Client.create_branch(full_name, branch_name, sha, token),
         encoded_content = Base.encode64(l10n_md),
         {:ok, _} <-
           Glossia.Github.Client.create_or_update_file(
             full_name,
             "L10N.md",
             %{
               message: "Add L10N.md for Glossia localization",
               content: encoded_content,
               branch: branch_name
             },
             token
           ),
         {:ok, pr} <-
           Glossia.Github.Client.create_pull_request(
             full_name,
             %{
               title: "Add L10N.md for Glossia localization",
               body:
                 "This PR was automatically created by [Glossia](https://glossia.ai) to set up localization for this repository.\n\nThe `L10N.md` file configures how Glossia processes and translates content in your project. Review the configuration and merge when ready.",
               head: branch_name,
               base: default_branch
             },
             token
           ) do
      {:ok, pr["html_url"]}
    end
  end

  defp record_setup_event(project, event_type, content, metadata) do
    sequence = Ingestion.max_setup_event_sequence(project.id) + 1
    metadata_json = JSON.encode!(metadata)

    Ingestion.record_setup_event(project.id, sequence, event_type, content || "", metadata_json)

    Projects.broadcast_setup_event(project, %{
      sequence: sequence,
      event_type: event_type,
      content: content || "",
      metadata: metadata_json
    })
  end

  defp humanize_error(:agent_session_failed),
    do: "The setup agent encountered an error and could not complete."

  defp humanize_error(:agent_timeout),
    do: "The setup agent timed out before completing."

  defp humanize_error({:github_token_failed, _}),
    do: "Could not authenticate with GitHub. Check the app installation."

  defp humanize_error(:setup_model_not_configured),
    do: "The setup model is not configured. Set GLOSSIA_SETUP_MINIMAX_API_KEY."

  defp humanize_error(:sandboxes_disabled),
    do: "Sandbox workflow execution is disabled."

  defp humanize_error(:sandbox_quota_exceeded),
    do: "The account has reached its active sandbox limit."

  defp humanize_error(:setup_already_running),
    do: "Project setup is already running."

  defp humanize_error(:setup_sandbox_id_changed),
    do: "Project setup changed while this run was starting."

  defp humanize_error({:deno_install_failed, _, _}),
    do: "The setup environment could not be initialized."

  defp humanize_error(reason) when is_binary(reason), do: reason
  defp humanize_error(reason), do: inspect(reason)

  defp setup_model_config do
    config = Application.get_env(:glossia, __MODULE__, [])
    minimax_api_key = Keyword.get(config, :minimax_api_key)
    model = Keyword.get(config, :model, "MiniMax-M2.5")

    if is_binary(minimax_api_key) and minimax_api_key != "" do
      {:ok, %{minimax_api_key: minimax_api_key, model: model}}
    else
      {:error, :setup_model_not_configured}
    end
  end

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
