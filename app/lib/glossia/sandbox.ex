defmodule Glossia.Sandbox do
  @moduledoc """
  Behaviour for sandboxed execution environments and shared agent session logic.

  Adapters (Docker for dev, Daytona for prod) implement the five primitive
  callbacks. The agent session orchestration -- uploading the Elixir agent
  binary, uploading config, launching the agent, polling for completion --
  lives here so it is written once.
  """

  require Logger

  @type sandbox_id :: String.t()

  @callback create(params :: map()) :: {:ok, sandbox_id()} | {:error, term()}
  @callback execute(sandbox_id(), command :: String.t(), opts :: keyword()) ::
              {:ok, map()} | {:error, term()}
  @callback upload_file(sandbox_id(), remote_path :: String.t(), content :: binary()) ::
              :ok | {:error, term()}
  @callback download_file(sandbox_id(), remote_path :: String.t()) ::
              {:ok, binary()} | {:error, term()}
  @callback delete(sandbox_id()) :: :ok | {:error, term()}

  @poll_interval_ms 2_000
  @max_poll_duration_ms 600_000
  @status_path "/tmp/agent-status.json"
  @config_path "/tmp/glossia-setup.json"
  @agent_binary_path "/tmp/glossia_agent"

  def adapter do
    Application.get_env(:glossia, :sandbox_adapter, Glossia.Sandbox.Docker)
  end

  @doc """
  Start an agent session inside a sandbox.

  Uploads the Elixir agent binary and config JSON, launches the agent,
  and polls `status.json` for completion. Sends
  `{:agent_done, :completed | :failed}` to `receiver` when finished.
  """
  @spec start_agent_session(module(), sandbox_id(), pid(), keyword()) ::
          {:ok, pid()} | {:error, term()}
  def start_agent_session(adapter, sandbox_id, receiver, opts) do
    pid =
      spawn_link(fn ->
        run_agent_session(adapter, sandbox_id, receiver, opts)
      end)

    {:ok, pid}
  end

  # -- Private agent session orchestration ------------------------------------

  defp run_agent_session(adapter, sandbox_id, receiver, opts) do
    server_url = Keyword.fetch!(opts, :server_url)
    session_token = Keyword.fetch!(opts, :session_token)
    project_id = Keyword.fetch!(opts, :project_id)
    config_json = Keyword.fetch!(opts, :config_json)

    clear_status_file(adapter, sandbox_id)

    with :ok <- install_agent(adapter, sandbox_id),
         :ok <- upload_config(adapter, sandbox_id, config_json),
         :ok <- run_agent(adapter, sandbox_id, server_url, session_token, project_id) do
      poll_loop(adapter, sandbox_id, receiver, 0)
    else
      {:error, reason} ->
        Logger.error("Failed to set up agent in sandbox #{sandbox_id}: #{inspect(reason)}")

        send(receiver, {:agent_done, :failed})
    end
  rescue
    error ->
      Logger.error("Agent session crashed in sandbox #{sandbox_id}: #{inspect(error)}")

      send(receiver, {:agent_done, :failed})
  end

  defp clear_status_file(adapter, sandbox_id) do
    adapter.execute(sandbox_id, "rm -f #{@status_path}", [])
  end

  defp install_agent(adapter, sandbox_id) do
    path = Application.app_dir(:glossia, "priv/agent/glossia_agent")

    if File.exists?(path) do
      binary = File.read!(path)

      with :ok <- adapter.upload_file(sandbox_id, @agent_binary_path, binary),
           {:ok, %{"exitCode" => 0}} <-
             adapter.execute(sandbox_id, "chmod +x #{@agent_binary_path}", []) do
        :ok
      else
        {:ok, %{"exitCode" => code}} ->
          {:error, {:agent_chmod_failed, code}}

        {:error, reason} ->
          {:error, {:agent_upload_failed, reason}}
      end
    else
      {:error, :agent_binary_not_available}
    end
  end

  defp upload_config(adapter, sandbox_id, config_json) do
    adapter.upload_file(sandbox_id, @config_path, config_json)
  end

  defp run_agent(adapter, sandbox_id, server_url, session_token, project_id) do
    # Docker containers can't reach host's localhost; use host.docker.internal.
    # On Daytona this is a no-op since server_url is a public URL.
    effective_url = String.replace(server_url, "://localhost", "://host.docker.internal")

    command =
      "nohup #{@agent_binary_path} " <>
        "--server-url=\"#{effective_url}\" " <>
        "--token=\"#{session_token}\" " <>
        "--project-id=\"#{project_id}\" " <>
        "--config-path=\"#{@config_path}\" " <>
        "> /tmp/agent-runner.log 2>&1 &"

    case adapter.execute(sandbox_id, command, []) do
      {:ok, _} ->
        Process.sleep(1_000)
        :ok

      {:error, reason} ->
        {:error, {:agent_run_failed, reason}}
    end
  end

  defp poll_loop(adapter, sandbox_id, receiver, elapsed_ms) do
    if elapsed_ms >= @max_poll_duration_ms do
      Logger.warning("Agent session timed out for sandbox #{sandbox_id}")
      send(receiver, {:agent_done, :failed})
    else
      case read_status(adapter, sandbox_id) do
        :completed ->
          send(receiver, {:agent_done, :completed})

        :failed ->
          send(receiver, {:agent_done, :failed})

        :running ->
          Process.sleep(@poll_interval_ms)
          poll_loop(adapter, sandbox_id, receiver, elapsed_ms + @poll_interval_ms)
      end
    end
  end

  defp read_status(adapter, sandbox_id) do
    case adapter.download_file(sandbox_id, @status_path) do
      {:ok, content} ->
        case JSON.decode(content) do
          {:ok, %{"status" => "completed"}} -> :completed
          {:ok, %{"status" => "failed"}} -> :failed
          {:ok, %{"status" => "running"}} -> :running
          _ -> :running
        end

      _ ->
        :running
    end
  end
end
