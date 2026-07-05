defmodule Glossia.Sandbox.Runner do
  @moduledoc false

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    sandbox_id = Keyword.fetch!(opts, :sandbox_id)
    root_path = Keyword.get(opts, :root_path) || default_root_path(sandbox_id)
    repo_path = Path.join(root_path, "repo")

    File.rm_rf!(root_path)
    File.mkdir_p!(repo_path)

    {:ok,
     %{
       sandbox_id: sandbox_id,
       root_path: Path.expand(root_path),
       repo_path: repo_path,
       command: nil
     }}
  end

  @impl true
  def handle_call({:execute, command, opts}, from, state) when is_binary(command) do
    start_command(state, from, fn -> safe_execute(state, command, opts) end)
  end

  def handle_call({:execute_shell, command, opts}, from, state) when is_binary(command) do
    start_command(state, from, fn -> run_shell_command(state, command, opts) end)
  end

  def handle_call({:download_file, path}, _from, state) do
    with {:ok, path} <- existing_sandbox_path(state, path),
         {:ok, content} <- File.read(path) do
      {:reply, {:ok, content}, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:upload_file, path, content}, _from, state) when is_binary(content) do
    with {:ok, path} <- writable_sandbox_path(state, path),
         :ok <- File.write(path, content) do
      {:reply, :ok, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:delete_file, path}, _from, state) do
    with {:ok, path} <- deletable_sandbox_path(state, path),
         {:ok, _paths} <- File.rm_rf(path) do
      {:reply, :ok, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:repo_path, _from, state) do
    {:reply, {:ok, state.repo_path}, state}
  end

  def handle_call(:delete, _from, state) do
    state = cancel_running_command(state)

    case File.rm_rf(state.root_path) do
      {:ok, _paths} -> {:stop, :normal, :ok, state}
      {:error, reason, path} -> {:reply, {:error, {:rm_rf_failed, path, reason}}, state}
    end
  end

  @impl true
  def handle_info({:command_done, ref, result}, %{command: %{ref: ref}} = state) do
    %{from: from, monitor: monitor} = state.command
    Process.demonitor(monitor, [:flush])
    GenServer.reply(from, result)
    {:noreply, %{state | command: nil}}
  end

  def handle_info(
        {:DOWN, monitor, :process, _pid, reason},
        %{command: %{monitor: monitor}} = state
      ) do
    GenServer.reply(state.command.from, {:error, reason})
    {:noreply, %{state | command: nil}}
  end

  def handle_info(_message, state), do: {:noreply, state}

  defp start_command(%{command: nil} = state, from, fun) do
    caller = self()
    ref = make_ref()

    {:ok, pid} = Task.start(fn -> send(caller, {:command_done, ref, fun.()}) end)
    monitor = Process.monitor(pid)

    {:noreply, %{state | command: %{ref: ref, pid: pid, monitor: monitor, from: from}}}
  end

  defp start_command(state, _from, _fun) do
    {:reply, {:error, :command_already_running}, state}
  end

  defp safe_execute(state, command, opts) do
    with :ok <- ensure_no_env(opts),
         {:ok, cwd} <- command_cwd(state, opts),
         {:ok, argv} <- Glossia.Sandbox.SafeCommand.parse(command) do
      output_limit =
        option(
          opts,
          :output_limit_bytes,
          Glossia.Sandbox.configured(:output_limit_bytes, 256_000)
        )

      run_safe_command(state, cwd, argv, output_limit)
    end
  end

  defp run_shell_command(state, command, opts) do
    timeout = option(opts, :timeout_ms, Glossia.Sandbox.configured(:command_timeout_ms, 120_000))

    output_limit =
      option(opts, :output_limit_bytes, Glossia.Sandbox.configured(:output_limit_bytes, 256_000))

    with {:ok, cwd} <- command_cwd(state, opts) do
      env = command_env(opts)

      {output, exit_status} =
        MuonTrap.cmd("sh", ["-lc", command],
          cd: cwd,
          env: env,
          timeout: timeout,
          stderr_to_stdout: true,
          into: ""
        )

      {:ok,
       %{
         "exitCode" => if(is_integer(exit_status), do: exit_status),
         "stdout" => truncate(output, output_limit),
         "stderr" => "",
         "timedOut" => exit_status == :timeout
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp command_cwd(state, opts) do
    case option(opts, :cwd, nil) do
      nil -> {:ok, state.root_path}
      cwd -> sandbox_path(state, cwd)
    end
  end

  defp ensure_no_env(opts) do
    case option(opts, :env, %{}) do
      env when env in [nil, %{}, []] -> :ok
      _env -> {:error, :env_not_supported_for_safe_commands}
    end
  end

  defp run_safe_command(_state, _cwd, ["echo" | args], limit) do
    safe_response(Enum.join(args, " ") <> "\n", 0, limit)
  end

  defp run_safe_command(_state, _cwd, ["printf" | args], limit) do
    safe_response(Enum.join(args, " "), 0, limit)
  end

  defp run_safe_command(_state, cwd, ["pwd"], limit) do
    safe_response(cwd <> "\n", 0, limit)
  end

  defp run_safe_command(_state, _cwd, ["true"], limit), do: safe_response("", 0, limit)

  defp run_safe_command(_state, _cwd, ["false"], limit), do: safe_response("", 1, limit)

  defp run_safe_command(state, cwd, ["cat" | paths], limit) when paths != [] do
    paths
    |> Enum.reduce_while({:ok, []}, fn path, {:ok, chunks} ->
      with {:ok, path} <- existing_sandbox_path(state, path, cwd),
           {:ok, content} <- File.read(path) do
        {:cont, {:ok, [content | chunks]}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, chunks} -> safe_response(chunks |> Enum.reverse() |> Enum.join(""), 0, limit)
      {:error, reason} -> {:error, reason}
    end
  end

  defp run_safe_command(state, cwd, ["ls" | args], limit) do
    paths = if args == [], do: ["."], else: args

    paths
    |> Enum.reduce_while({:ok, []}, fn path, {:ok, chunks} ->
      with {:ok, path} <- existing_sandbox_path(state, path, cwd),
           {:ok, entries} <- File.ls(path) do
        output = entries |> Enum.sort() |> Enum.join("\n") |> trailing_newline()
        {:cont, {:ok, [output | chunks]}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, chunks} -> safe_response(chunks |> Enum.reverse() |> Enum.join(""), 0, limit)
      {:error, reason} -> {:error, reason}
    end
  end

  defp run_safe_command(state, cwd, ["mkdir" | args], limit) do
    with {:ok, paths} <- mkdir_paths(args) do
      paths
      |> Enum.reduce_while(:ok, fn path, :ok ->
        with {:ok, path} <- writable_sandbox_path(state, path, cwd),
             :ok <- File.mkdir_p(path) do
          {:cont, :ok}
        else
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
      |> case do
        :ok -> safe_response("", 0, limit)
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp run_safe_command(state, cwd, ["rm" | args], limit) do
    with {:ok, paths} <- rm_paths(args) do
      paths
      |> Enum.reduce_while(:ok, fn path, :ok ->
        with {:ok, path} <- deletable_sandbox_path(state, path, cwd),
             {:ok, _paths} <- File.rm_rf(path) do
          {:cont, :ok}
        else
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
      |> case do
        :ok -> safe_response("", 0, limit)
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp run_safe_command(_state, _cwd, _argv, _limit), do: {:error, :invalid_command_args}

  defp mkdir_paths(["-p" | paths]) when paths != [], do: {:ok, paths}
  defp mkdir_paths(paths) when paths != [], do: {:ok, paths}
  defp mkdir_paths(_args), do: {:error, :invalid_command_args}

  defp rm_paths(args) do
    {flags, paths} = Enum.split_while(args, &String.starts_with?(&1, "-"))

    cond do
      paths == [] -> {:error, :invalid_command_args}
      Enum.all?(flags, &(&1 in ["-r", "-f", "-rf", "-fr"])) -> {:ok, paths}
      true -> {:error, :invalid_command_args}
    end
  end

  defp safe_response(output, exit_status, limit) do
    {:ok,
     %{
       "exitCode" => exit_status,
       "stdout" => truncate(output, limit),
       "stderr" => "",
       "timedOut" => false
     }}
  end

  defp trailing_newline(""), do: ""
  defp trailing_newline(output), do: output <> "\n"

  defp sandbox_path(state, path) when is_binary(path) do
    sandbox_path(state, path, state.root_path)
  end

  defp sandbox_path(_state, _path), do: {:error, :invalid_path}

  defp sandbox_path(state, path, cwd) when is_binary(path) and is_binary(cwd) do
    expanded = Path.expand(path, cwd)
    root = state.root_path

    if expanded == root or String.starts_with?(expanded, root <> "/") do
      {:ok, expanded}
    else
      {:error, :path_outside_sandbox}
    end
  end

  defp sandbox_path(_state, _path, _cwd), do: {:error, :invalid_path}

  defp existing_sandbox_path(state, path) when is_binary(path) do
    existing_sandbox_path(state, path, state.root_path)
  end

  defp existing_sandbox_path(state, path, cwd) when is_binary(path) and is_binary(cwd) do
    with {:ok, path} <- sandbox_path(state, path, cwd),
         :ok <- ensure_no_symlink_path(state, path, :existing) do
      {:ok, path}
    end
  end

  defp writable_sandbox_path(state, path) when is_binary(path) do
    writable_sandbox_path(state, path, state.root_path)
  end

  defp writable_sandbox_path(state, path, cwd) when is_binary(path) and is_binary(cwd) do
    with {:ok, path} <- sandbox_path(state, path, cwd),
         :ok <- ensure_no_symlink_path(state, Path.dirname(path), :allow_missing),
         :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- reject_existing_symlink(path) do
      {:ok, path}
    end
  end

  defp deletable_sandbox_path(state, path) when is_binary(path) do
    deletable_sandbox_path(state, path, state.root_path)
  end

  defp deletable_sandbox_path(state, path, cwd) when is_binary(path) and is_binary(cwd) do
    with {:ok, path} <- sandbox_path(state, path, cwd),
         :ok <- ensure_no_symlink_path(state, path, :allow_missing),
         :ok <- reject_existing_symlink(path) do
      {:ok, path}
    end
  end

  defp reject_existing_symlink(path) do
    case File.lstat(path) do
      {:ok, %{type: :symlink}} -> {:error, :path_outside_sandbox}
      {:ok, _stat} -> :ok
      {:error, :enoent} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_no_symlink_path(state, path, mode) do
    relative = Path.relative_to(path, state.root_path)

    state.root_path
    |> symlink_components(relative)
    |> Enum.reduce_while(:ok, fn component_path, :ok ->
      case File.lstat(component_path) do
        {:ok, %{type: :symlink}} -> {:halt, {:error, :path_outside_sandbox}}
        {:ok, _stat} -> {:cont, :ok}
        {:error, :enoent} when mode == :allow_missing -> {:halt, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp symlink_components(root, "."), do: [root]

  defp symlink_components(root, relative) do
    components =
      relative
      |> Path.split()
      |> Enum.scan(root, &Path.join(&2, &1))

    [root | components]
  end

  defp command_env(opts) do
    opts
    |> option(:env, %{})
    |> case do
      env when is_map(env) ->
        Enum.map(env, fn {key, value} -> {to_string(key), to_string(value)} end)

      env when is_list(env) ->
        Enum.map(env, fn {key, value} -> {to_string(key), to_string(value)} end)

      _ ->
        []
    end
  end

  defp cancel_running_command(%{command: nil} = state), do: state

  defp cancel_running_command(%{command: %{pid: pid, monitor: monitor}} = state) do
    Process.exit(pid, :kill)
    Process.demonitor(monitor, [:flush])
    %{state | command: nil}
  end

  defp option(opts, key, default) when is_list(opts) do
    case Keyword.fetch(opts, key) do
      {:ok, nil} -> default
      {:ok, value} -> value
      :error -> default
    end
  end

  defp option(opts, key, default) when is_map(opts) do
    Map.get(opts, key, Map.get(opts, Atom.to_string(key), default)) || default
  end

  defp option(_opts, _key, default), do: default

  defp truncate(output, limit) when is_integer(limit) and byte_size(output) > limit do
    binary_part(output, 0, limit)
  end

  defp truncate(output, _limit), do: output

  defp default_root_path(sandbox_id) do
    Path.join(System.tmp_dir!(), "glossia-sandbox-#{sandbox_id}")
  end
end
