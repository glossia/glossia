defmodule Glossia.Projects.SetupSandboxJob do
  @moduledoc false

  @doc false
  def run!(path) when is_binary(path) do
    job = path |> File.read!() |> JSON.decode!()
    event_path = Map.fetch!(job, "event_path")
    File.write!(event_path, "")

    collector = start_collector(event_path)

    result =
      Glossia.Projects.SetupHarness.run(callbacks(job), collector,
        repo_path: Map.fetch!(job, "repo_path"),
        repository: Map.fetch!(job, "repository"),
        target_languages: Map.get(job, "target_languages", []),
        harness: Map.get(job, "harness", %{}),
        timeout_ms: Map.get(job, "timeout_ms", 660_000)
      )

    stop_collector(collector)

    case result do
      :ok -> :ok
      {:error, reason} -> raise "isolated setup job failed: #{inspect(reason)}"
    end
  end

  defp callbacks(job) do
    root_path = job |> Map.fetch!("repo_path") |> Path.dirname() |> Path.expand()

    %{
      execute_shell: fn command, opts -> execute_shell(root_path, command, opts) end,
      upload_file: fn path, content -> write_file(root_path, path, content) end,
      download_file: fn path -> read_file(root_path, path) end
    }
  end

  defp execute_shell(root_path, command, opts) do
    cwd = Keyword.get(opts, :cwd, root_path)

    with {:ok, cwd} <- existing_sandbox_path(root_path, cwd) do
      timeout = Keyword.get(opts, :timeout_ms, 120_000)
      output_limit = Keyword.get(opts, :output_limit_bytes, 256_000)

      {output, exit_status} =
        MuonTrap.cmd("sh", ["-c", ~s(exec "$@" </dev/null), "sh", "sh", "-lc", command],
          cd: cwd,
          env: normalize_env(Keyword.get(opts, :env, %{})),
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
    end
  end

  defp write_file(root_path, path, content) do
    with {:ok, path} <- writable_sandbox_path(root_path, path),
         :ok <- File.write(path, content) do
      :ok
    end
  end

  defp read_file(root_path, path) do
    with {:ok, path} <- existing_sandbox_path(root_path, path) do
      File.read(path)
    end
  end

  defp sandbox_path(root_path, path) when is_binary(path) do
    path = Path.expand(path, root_path)

    if path == root_path or String.starts_with?(path, root_path <> "/") do
      {:ok, path}
    else
      {:error, :path_outside_sandbox}
    end
  end

  defp existing_sandbox_path(root_path, path) do
    with {:ok, path} <- sandbox_path(root_path, path),
         :ok <- ensure_no_symlink_path(root_path, path, :existing) do
      {:ok, path}
    end
  end

  defp writable_sandbox_path(root_path, path) do
    with {:ok, path} <- sandbox_path(root_path, path),
         :ok <- ensure_no_symlink_path(root_path, Path.dirname(path), :allow_missing),
         :ok <- File.mkdir_p(Path.dirname(path)),
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

  defp ensure_no_symlink_path(root_path, path, mode) do
    relative = Path.relative_to(path, root_path)

    root_path
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

  defp symlink_components(root_path, "."), do: [root_path]

  defp symlink_components(root_path, relative) do
    components =
      relative
      |> Path.split()
      |> Enum.scan(root_path, &Path.join(&2, &1))

    [root_path | components]
  end

  defp start_collector(event_path) do
    spawn_link(fn -> collect_events(event_path) end)
  end

  defp collect_events(event_path) do
    receive do
      {:agent_event, event} ->
        File.write!(event_path, JSON.encode!(event) <> "\n", [:append])
        collect_events(event_path)

      {:stop, caller, ref} ->
        send(caller, {:collector_stopped, ref})
    end
  end

  defp stop_collector(collector) do
    ref = make_ref()
    send(collector, {:stop, self(), ref})

    receive do
      {:collector_stopped, ^ref} -> :ok
    after
      5_000 -> raise "isolated setup event collector did not stop"
    end
  end

  defp normalize_env(env) when is_map(env) do
    Enum.map(env, fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp normalize_env(env) when is_list(env), do: env
  defp normalize_env(_env), do: []

  defp truncate(output, limit) when byte_size(output) > limit,
    do: binary_part(output, 0, limit)

  defp truncate(output, _limit), do: output
end
