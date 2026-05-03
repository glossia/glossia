defmodule Glossia.Projects.Setup do
  @compile {:no_warn_undefined, [Glossia.Sandbox]}
  @moduledoc """
  Runs the project setup process: creates a sandbox, starts the agent,
  waits for completion, and optionally opens a PR with the generated
  GLOSSIA.md file.

  Called by `Glossia.Projects.SetupWorker` (Oban) for retry semantics
  and lifecycle management.
  """

  require Logger

  alias Glossia.{Events, Ingestion, Projects}

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
         {:ok, sandbox_id} <- ensure_sandbox(project, sandbox),
         {:ok, _status} <- start_agent_and_wait(sandbox, sandbox_id, project, token),
         result <- maybe_create_pr(project, sandbox, sandbox_id) do
      sandbox.delete(sandbox_id)
      Projects.update_project_sandbox_id(project, nil)

      case result do
        {:ok, pr_url} ->
          record_setup_event(project, "pr_created", pr_url, %{
            "label" => "pull_request",
            "repo" => project.github_repo_full_name || ""
          })

          Projects.update_project_setup_status(project, "completed")
          Projects.broadcast_setup_status(project, "completed")

          Events.emit("project.setup_completed", account, nil,
            resource_type: "project",
            resource_id: to_string(project.id),
            resource_path: "/#{account.handle}/#{project.handle}",
            summary: "Setup completed for #{project.handle}, PR: #{pr_url}"
          )

          :ok

        :skipped_pr ->
          Logger.info(
            "Setup completed for project #{project.id}, PR creation skipped (no GitHub App)"
          )

          Projects.update_project_setup_status(project, "completed")
          Projects.broadcast_setup_status(project, "completed")

          Events.emit("project.setup_completed", account, nil,
            resource_type: "project",
            resource_id: to_string(project.id),
            resource_path: "/#{account.handle}/#{project.handle}",
            summary: "Setup completed for #{project.handle} (PR skipped, no GitHub App)"
          )

          :ok

        :no_language_md ->
          error_msg =
            "Setup finished without generating GLOSSIA.md, so no pull request was created."

          Logger.error("Setup failed for project #{project.id}: #{error_msg}")
          Projects.update_project_setup_status(project, "failed", error_msg)
          Projects.broadcast_setup_status(project, "failed")

          Events.emit("project.setup_failed", account, nil,
            resource_type: "project",
            resource_id: to_string(project.id),
            resource_path: "/#{account.handle}/#{project.handle}",
            summary: "Setup failed for #{project.handle}: #{error_msg}"
          )

          {:error, :language_md_missing}

        {:error, reason} ->
          error_msg = humanize_error(reason)
          Logger.error("PR creation failed for project #{project.id}: #{inspect(reason)}")
          Projects.update_project_setup_status(project, "failed", error_msg)
          Projects.broadcast_setup_status(project, "failed")
          {:error, {:pr_creation_failed, reason}}
      end
    else
      {:error, reason} ->
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

  defp ensure_sandbox(project, sandbox) do
    case project.setup_sandbox_id do
      nil ->
        create_sandbox(project, sandbox)

      existing_id ->
        if sandbox_alive?(sandbox, existing_id) do
          Logger.info("Resuming sandbox #{existing_id} for project #{project.id}")
          {:ok, existing_id}
        else
          Logger.info("Stale sandbox #{existing_id} for project #{project.id}, creating new one")

          Projects.update_project_sandbox_id(project, nil)
          create_sandbox(project, sandbox)
        end
    end
  end

  defp create_sandbox(project, sandbox) do
    params = %{
      language: "node",
      ephemeral: true,
      auto_stop_interval: 0,
      labels: %{
        "project_id" => to_string(project.id),
        "purpose" => "project_setup"
      }
    }

    case sandbox.create(params) do
      {:ok, sandbox_id} ->
        Projects.update_project_sandbox_id(project, sandbox_id)
        {:ok, sandbox_id}

      {:error, _} = err ->
        err
    end
  end

  defp sandbox_alive?(sandbox, sandbox_id) do
    case sandbox.execute(sandbox_id, "echo ok") do
      {:ok, %{"exitCode" => 0}} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  defp start_agent_and_wait(sandbox, sandbox_id, project, github_token) do
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
        repo_path: "/home/user/repo",
        target_languages: project.setup_target_languages || []
      })

    {:ok, _pid} =
      Glossia.Sandbox.start_agent_session(sandbox, sandbox_id, self(),
        server_url: server_url,
        session_token: session_token,
        project_id: project.id,
        config_json: config_json
      )

    wait_for_completion(project)
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

  defp maybe_create_pr(project, sandbox, sandbox_id) do
    case sandbox.download_file(sandbox_id, "/home/user/repo/GLOSSIA.md") do
      {:ok, language_md} when is_binary(language_md) and language_md != "" ->
        create_pr(project, language_md)

      _ ->
        :no_language_md
    end
  end

  defp create_pr(project, language_md) do
    installation = project.github_installation

    if is_nil(installation) do
      Logger.info("No GitHub installation linked, skipping PR creation for project #{project.id}")

      :skipped_pr
    else
      case Glossia.Github.App.installation_token(installation.github_installation_id) do
        {:ok, token} ->
          do_create_pr(project, token, language_md)

        {:error, :not_configured} ->
          Logger.info("GitHub App not configured, skipping PR creation for project #{project.id}")

          :skipped_pr

        {:error, reason} ->
          {:error, {:github_token_failed, reason}}
      end
    end
  end

  defp do_create_pr(project, token, language_md) do
    full_name = project.github_repo_full_name
    default_branch = project.github_repo_default_branch || "main"
    branch_name = "glossia/setup-localization"

    with {:ok, ref_data} <-
           Glossia.Github.Client.get_ref(full_name, "heads/#{default_branch}", token),
         sha = ref_data["object"]["sha"],
         {:ok, _} <-
           Glossia.Github.Client.create_branch(full_name, branch_name, sha, token),
         encoded_content = Base.encode64(language_md),
         {:ok, _} <-
           Glossia.Github.Client.create_or_update_file(
             full_name,
             "GLOSSIA.md",
             %{
               message: "Add GLOSSIA.md for Glossia localization",
               content: encoded_content,
               branch: branch_name
             },
             token
           ),
         {:ok, pr} <-
           Glossia.Github.Client.create_pull_request(
             full_name,
             %{
               title: "Add GLOSSIA.md for Glossia localization",
               body:
                 "This PR was automatically created by [Glossia](https://glossia.ai) to set up localization for this repository.\n\nThe `GLOSSIA.md` file configures how Glossia processes and translates content in your project. Review the configuration and merge when ready.",
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

  defp humanize_error({:deno_install_failed, _, _}),
    do: "The setup environment could not be initialized."

  defp humanize_error(reason) when is_binary(reason), do: reason
  defp humanize_error(reason), do: inspect(reason)
end
