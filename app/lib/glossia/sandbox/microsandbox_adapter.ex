defmodule Glossia.Sandbox.MicrosandboxAdapter do
  @moduledoc """
  Local Microsandbox-backed sandbox adapter.

  This is intended for fast workflow sandbox checks on a developer machine with
  the `msb` CLI installed. Production-like reproduction uses the cluster adapter.
  """

  @behaviour Glossia.Sandbox

  @impl true
  def create(params) when is_map(params) do
    sandbox_id = to_string(params[:id] || params["id"] || Ecto.UUID.generate())
    name = sandbox_name(sandbox_id)
    image = configured(:microsandbox_image, "node:22-bookworm")

    with {_, 0} <- msb(["run", "-d", image, "--name", name], timeout: boot_timeout()),
         :ok <- ensure_repo_path(sandbox_id) do
      {:ok, sandbox_id}
    else
      {:error, reason} -> {:error, reason}
      {output, status} -> {:error, {:microsandbox_create_failed, status, output}}
    end
  end

  @impl true
  def execute(sandbox_id, command, opts \\ []) when is_binary(command) do
    with :ok <- ensure_no_env(opts),
         {:ok, argv} <- Glossia.Sandbox.SafeCommand.parse(command),
         {:ok, opts} <- normalize_public_exec_opts(sandbox_id, opts) do
      execute_argv(sandbox_id, argv, opts)
    end
  end

  defp execute_argv(sandbox_id, argv, opts) do
    timeout = option(opts, :timeout_ms, configured(:command_timeout_ms, 120_000))
    output_limit = option(opts, :output_limit_bytes, configured(:output_limit_bytes, 256_000))
    args = ["exec"] ++ exec_opts(opts) ++ [sandbox_name(sandbox_id), "--"] ++ argv
    {output, status} = msb(args, timeout: timeout)

    {:ok,
     %{
       "exitCode" => if(is_integer(status), do: status),
       "stdout" => truncate(output, output_limit),
       "stderr" => "",
       "timedOut" => status == :timeout
     }}
  end

  defp execute_shell(sandbox_id, command, opts \\ []) when is_binary(command) do
    timeout = option(opts, :timeout_ms, configured(:command_timeout_ms, 120_000))
    output_limit = option(opts, :output_limit_bytes, configured(:output_limit_bytes, 256_000))
    args = ["exec"] ++ exec_opts(opts) ++ [sandbox_name(sandbox_id), "--", "sh", "-lc", command]
    {output, status} = msb(args, timeout: timeout)

    {:ok,
     %{
       "exitCode" => if(is_integer(status), do: status),
       "stdout" => truncate(output, output_limit),
       "stderr" => "",
       "timedOut" => status == :timeout
     }}
  end

  @impl true
  def delete(sandbox_id) do
    name = sandbox_name(sandbox_id)

    case msb(["rm", name], timeout: 30_000) do
      {_, 0} ->
        :ok

      _ ->
        msb(["stop", name], timeout: 30_000)

        case msb(["rm", name], timeout: 30_000) do
          {_, 0} -> :ok
          {output, status} -> {:error, {:microsandbox_delete_failed, status, output}}
        end
    end
  end

  @impl true
  def download_file(sandbox_id, path) when is_binary(path) do
    with {:ok, path} <- workspace_path(sandbox_id, path) do
      command = "base64 #{shell_quote(path)}"

      with {:ok, %{"exitCode" => 0, "stdout" => encoded}} <- execute_shell(sandbox_id, command),
           {:ok, content} <- Base.decode64(String.replace(encoded, ~r/\s+/, "")) do
        {:ok, content}
      else
        {:ok, result} -> {:error, {:read_failed, result}}
        :error -> {:error, :invalid_base64}
      end
    end
  end

  @impl true
  def upload_file(sandbox_id, path, content) when is_binary(path) and is_binary(content) do
    with {:ok, path} <- workspace_path(sandbox_id, path) do
      encoded = Base.encode64(content)

      command =
        [
          "mkdir -p #{shell_quote(Path.dirname(path))}",
          "printf %s #{shell_quote(encoded)} | base64 -d > #{shell_quote(path)}"
        ]
        |> Enum.join(" && ")

      case execute_shell(sandbox_id, command) do
        {:ok, %{"exitCode" => 0}} -> :ok
        {:ok, result} -> {:error, {:write_failed, result}}
      end
    end
  end

  @impl true
  def delete_file(sandbox_id, path) when is_binary(path) do
    with {:ok, path} <- workspace_path(sandbox_id, path) do
      case execute_shell(sandbox_id, "rm -rf #{shell_quote(path)}") do
        {:ok, %{"exitCode" => 0}} -> :ok
        {:ok, result} -> {:error, {:delete_failed, result}}
      end
    end
  end

  @impl true
  def repo_path(_sandbox_id), do: {:ok, configured(:microsandbox_repo_path, "/home/user/repo")}

  @impl true
  def start_agent_session(sandbox_id, caller, opts) when is_pid(caller) do
    Task.start(fn -> run_agent_session(sandbox_id, caller, opts) end)
  end

  defp run_agent_session(sandbox_id, caller, opts) do
    with {:ok, repo_path} <- repo_path(sandbox_id),
         config_json <- Keyword.fetch!(opts, :config_json),
         config_path <- Path.join(Path.dirname(repo_path), "glossia-setup.json"),
         :ok <- upload_file(sandbox_id, config_path, config_json),
         command <- agent_command(opts, config_path),
         {:ok, result} <-
           execute_shell(sandbox_id, command, timeout_ms: Keyword.get(opts, :timeout_ms, 660_000)) do
      status = if result["exitCode"] == 0, do: :completed, else: :failed
      send(caller, {:agent_done, status})
    else
      _error -> send(caller, {:agent_done, :failed})
    end
  end

  defp ensure_repo_path(sandbox_id) do
    with {:ok, repo_path} <- repo_path(sandbox_id),
         {:ok, %{"exitCode" => 0}} <-
           execute_shell(sandbox_id, "mkdir -p #{shell_quote(repo_path)}") do
      :ok
    else
      {:ok, result} -> {:error, {:repo_path_failed, result}}
    end
  end

  defp agent_command(opts, config_path) do
    server_url = Keyword.fetch!(opts, :server_url)
    project_id = Keyword.fetch!(opts, :project_id)
    session_token = Keyword.fetch!(opts, :session_token)
    script_url = URI.merge(server_url, "/agent/scripts/mod.ts") |> to_string()
    deno = configured(:microsandbox_deno_command, "deno")

    [
      deno,
      "run",
      "--allow-all",
      script_url,
      "--server-url=#{server_url}",
      "--token=#{session_token}",
      "--project-id=#{project_id}",
      "--config-path=#{config_path}"
    ]
    |> Enum.map(&shell_quote/1)
    |> Enum.join(" ")
  end

  defp exec_opts(opts) do
    env_args =
      opts
      |> Keyword.get(:env, %{})
      |> case do
        env when is_map(env) ->
          Enum.flat_map(env, fn {key, value} -> ["-e", "#{key}=#{value}"] end)

        _ ->
          []
      end

    cwd_args =
      case Keyword.get(opts, :cwd) do
        cwd when is_binary(cwd) and cwd != "" -> ["-w", cwd]
        _ -> []
      end

    env_args ++ cwd_args
  end

  defp option(opts, key, default) when is_list(opts) do
    case Keyword.fetch(opts, key) do
      {:ok, nil} -> default
      {:ok, value} -> value
      :error -> default
    end
  end

  defp option(_opts, _key, default), do: default

  defp ensure_no_env(opts) do
    case Keyword.get(opts, :env, %{}) do
      env when env in [nil, %{}, []] -> :ok
      _env -> {:error, :env_not_supported_for_safe_commands}
    end
  end

  defp normalize_public_exec_opts(sandbox_id, opts) do
    case Keyword.get(opts, :cwd) do
      nil ->
        {:ok, Keyword.delete(opts, :cwd)}

      cwd when is_binary(cwd) ->
        with {:ok, cwd} <- workspace_path(sandbox_id, cwd) do
          {:ok, Keyword.put(opts, :cwd, cwd)}
        end

      _cwd ->
        {:error, :invalid_path}
    end
  end

  defp workspace_path(sandbox_id, path) when is_binary(path) do
    with {:ok, repo_path} <- repo_path(sandbox_id) do
      root = Path.dirname(repo_path)
      expanded = Path.expand(path, root)

      if expanded == root or String.starts_with?(expanded, root <> "/") do
        {:ok, expanded}
      else
        {:error, :path_outside_sandbox}
      end
    end
  end

  defp msb(args, opts) do
    MuonTrap.cmd("msb", args,
      timeout: Keyword.get(opts, :timeout, 120_000),
      stderr_to_stdout: true,
      into: ""
    )
  end

  defp configured(key, default), do: Glossia.Sandbox.configured(key, default)

  defp boot_timeout do
    :glossia
    |> Application.get_env(:flame, [])
    |> Keyword.get(:boot_timeout, 120_000)
  end

  defp sandbox_name(sandbox_id) do
    "glossia-" <> String.replace(sandbox_id, "-", "")
  end

  defp truncate(output, limit) when byte_size(output) > limit do
    binary_part(output, 0, limit)
  end

  defp truncate(output, _limit), do: output

  defp shell_quote(value) do
    value = to_string(value)
    "'" <> String.replace(value, "'", "'\\''") <> "'"
  end
end
