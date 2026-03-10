defmodule Glossia.Translations.Translate do
  @moduledoc """
  Runs the translation process: creates a sandbox, clones the repo,
  starts the agent, waits for completion, and cleans up.

  Called by `Glossia.Translations.TranslateWorker` (Oban) for retry
  semantics and lifecycle management.
  """

  require Logger

  alias Glossia.Translations

  def run(project, account, translation) do
    do_run(project, account, translation)
  rescue
    exception ->
      error_msg = Exception.message(exception)
      Logger.error("Translation crashed for #{translation.id}: #{error_msg}")

      Translations.update_translation_status(translation, "failed", error: error_msg)
      Translations.broadcast_translation_event(translation, :failed)

      :ok
  end

  defp do_run(project, _account, translation) do
    Translations.update_translation_status(translation, "running")
    Translations.broadcast_translation_event(translation, :running)

    case project.content_source do
      "local_git" -> run_locally(project, translation)
      _ -> run_in_sandbox(project, translation)
    end
  end

  defp run_locally(project, translation) do
    case Glossia.ContentSource.LocalGit.repo_path(project) do
      {:ok, repo_path} ->
        minimax_api_key = Application.get_env(:glossia, Glossia.Minimax)[:api_key] || ""
        emitter = GlossiaAgent.Events.LocalEmitter.new(self())

        pid =
          spawn_link(fn ->
            GlossiaAgent.translate(
              repo_path: repo_path,
              minimax_api_key: minimax_api_key,
              model: "MiniMax-M2.5",
              emitter: emitter
            )
          end)

        old_trap = Process.flag(:trap_exit, true)
        result = wait_for_local_completion(translation)
        Process.flag(:trap_exit, old_trap)

        case result do
          {:ok, :completed} ->
            Translations.update_translation_status(translation, "completed")
            Translations.broadcast_translation_event(translation, :completed)
            Logger.info("Translation #{translation.id} completed successfully (local)")
            _ = pid
            :ok

          {:error, reason} ->
            error_msg = humanize_error(reason)
            Logger.error("Translation #{translation.id} failed (local): #{inspect(reason)}")
            Translations.update_translation_status(translation, "failed", error: error_msg)
            Translations.broadcast_translation_event(translation, :failed)
            :ok
        end

      {:error, reason} ->
        error_msg = humanize_error(reason)
        Logger.error("Translation #{translation.id} failed: #{inspect(reason)}")
        Translations.update_translation_status(translation, "failed", error: error_msg)
        Translations.broadcast_translation_event(translation, :failed)
        :ok
    end
  end

  defp wait_for_local_completion(translation) do
    receive do
      {:agent_done, :completed} ->
        {:ok, :completed}

      {:agent_done, {:failed, reason}} ->
        {:error, reason}

      {:agent_event, %{type: type, content: content}} ->
        Logger.debug("Agent event [#{type}]: #{String.slice(content, 0, 200)}")
        wait_for_local_completion(translation)

      {:EXIT, _pid, :normal} ->
        {:ok, :completed}

      {:EXIT, _pid, reason} ->
        {:error, {:agent_crashed, reason}}
    after
      660_000 ->
        {:error, :agent_timeout}
    end
  end

  defp run_in_sandbox(project, translation) do
    sandbox = Glossia.Sandbox.adapter()

    with {:ok, token} <- get_clone_token(project),
         {:ok, sandbox_id} <- create_sandbox(project, sandbox),
         :ok <- store_sandbox_id(translation, sandbox_id),
         :ok <- clone_repo(sandbox, sandbox_id, project, token),
         {:ok, _status} <- start_agent_and_wait(sandbox, sandbox_id, project, translation) do
      sandbox.delete(sandbox_id)
      Translations.update_translation_status(translation, "completed")
      Translations.broadcast_translation_event(translation, :completed)

      Logger.info("Translation #{translation.id} completed successfully")
      :ok
    else
      {:error, reason} ->
        error_msg = humanize_error(reason)
        Logger.error("Translation #{translation.id} failed: #{inspect(reason)}")
        Translations.update_translation_status(translation, "failed", error: error_msg)
        Translations.broadcast_translation_event(translation, :failed)

        best_effort_cleanup(translation, sandbox)
        :ok
    end
  end

  defp get_clone_token(project) do
    case project.content_source do
      "github" ->
        installation = project.github_installation

        if is_nil(installation) do
          {:ok, nil}
        else
          case Glossia.Github.App.installation_token(installation.github_installation_id) do
            {:ok, token} -> {:ok, token}
            {:error, :not_configured} -> {:ok, nil}
            {:error, reason} -> {:error, {:github_token_failed, reason}}
          end
        end

      _ ->
        {:ok, nil}
    end
  end

  defp create_sandbox(project, sandbox) do
    params = %{
      language: "node",
      ephemeral: true,
      auto_stop_interval: 0,
      labels: %{
        "purpose" => "translation"
      }
    }

    params =
      case project.content_source do
        "local_git" ->
          case Glossia.ContentSource.LocalGit.repo_path(project) do
            {:ok, host_path} ->
              Map.put(params, :volumes, [{host_path, "/mnt/repo"}])

            {:error, _} ->
              params
          end

        _ ->
          params
      end

    sandbox.create(params)
  end

  defp store_sandbox_id(translation, sandbox_id) do
    case Translations.update_translation_sandbox_id(translation, sandbox_id) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, {:sandbox_id_update_failed, reason}}
    end
  end

  defp clone_repo(sandbox, sandbox_id, project, token) do
    clone_command =
      case project.content_source do
        "github" ->
          repo = project.github_repo_full_name

          if token do
            "git clone https://x-access-token:#{token}@github.com/#{repo}.git /home/user/repo"
          else
            "git clone https://github.com/#{repo}.git /home/user/repo"
          end

        "local_git" ->
          "git clone /mnt/repo /home/user/repo"

        _ ->
          "echo 'Unknown content source'"
      end

    case sandbox.execute(sandbox_id, clone_command, []) do
      {:ok, %{"exitCode" => 0}} -> :ok
      {:ok, %{"exitCode" => code, "result" => output}} -> {:error, {:clone_failed, code, output}}
      {:error, reason} -> {:error, {:clone_failed, reason}}
    end
  end

  defp start_agent_and_wait(sandbox, sandbox_id, project, translation) do
    # Trap exits so the linked agent process's crash is received as a
    # message instead of killing this process (and the Oban worker).
    old_trap = Process.flag(:trap_exit, true)

    session_token =
      Phoenix.Token.sign(
        GlossiaWeb.Endpoint,
        "agent_session",
        project.id
      )

    server_url = GlossiaWeb.Endpoint.url()
    minimax_api_key = Application.get_env(:glossia, Glossia.Minimax)[:api_key] || ""

    config_json =
      JSON.encode!(%{
        mode: "translate",
        translation_id: translation.id,
        github_repo_full_name: project.github_repo_full_name,
        github_repo_default_branch: project.github_repo_default_branch || "main",
        repo_path: "/home/user/repo",
        target_languages: translation.target_languages || [],
        source_language: translation.source_language || "en",
        commit_sha: translation.commit_sha,
        minimax_api_key: minimax_api_key,
        model: "minimax/MiniMax-M2.5"
      })

    {:ok, _pid} =
      Glossia.Sandbox.start_agent_session(sandbox, sandbox_id, self(),
        server_url: server_url,
        session_token: session_token,
        project_id: project.id,
        config_json: config_json
      )

    result = wait_for_completion(translation)
    Process.flag(:trap_exit, old_trap)
    result
  end

  defp wait_for_completion(translation) do
    receive do
      {:agent_done, :completed} ->
        Logger.info("Agent session completed for translation #{translation.id}")
        {:ok, :completed}

      {:agent_done, :failed} ->
        Logger.warning("Agent session failed for translation #{translation.id}")
        {:error, :agent_session_failed}

      {:EXIT, _pid, _reason} ->
        Logger.warning("Agent process exited for translation #{translation.id}")
        {:error, :agent_session_failed}
    after
      660_000 ->
        Logger.warning("Agent session timed out for translation #{translation.id}")
        {:error, :agent_timeout}
    end
  end

  defp best_effort_cleanup(translation, sandbox) do
    translation = Glossia.Repo.reload(translation)

    if translation && translation.sandbox_id do
      case sandbox.delete(translation.sandbox_id) do
        :ok ->
          :ok

        {:error, reason} ->
          Logger.warning(
            "Failed to cleanup sandbox #{translation.sandbox_id}: #{inspect(reason)}"
          )
      end
    end
  end

  defp humanize_error(:agent_session_failed),
    do: "The translation agent encountered an error and could not complete."

  defp humanize_error(:agent_timeout),
    do: "The translation agent timed out before completing."

  defp humanize_error({:github_token_failed, _}),
    do: "Could not authenticate with GitHub. Check the app installation."

  defp humanize_error({:clone_failed, _, _}),
    do: "Failed to clone the repository."

  defp humanize_error({:clone_failed, _}),
    do: "Failed to clone the repository."

  defp humanize_error(reason) when is_binary(reason), do: reason
  defp humanize_error(reason), do: inspect(reason)
end
