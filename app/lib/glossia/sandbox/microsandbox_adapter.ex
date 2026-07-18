defmodule Glossia.Sandbox.MicrosandboxAdapter do
  @moduledoc """
  Local Microsandbox-backed sandbox adapter.

  This is intended for fast workflow sandbox checks on a developer machine with
  the `msb` command installed. It boots the same Glossia release image used by
  production and executes workflow logic inside that isolated release.
  """

  @behaviour Glossia.Sandbox

  @impl true
  def create(params) when is_map(params) do
    sandbox_id = to_string(params[:id] || params["id"] || Ecto.UUID.generate())
    name = sandbox_name(sandbox_id)
    image = configured(:microsandbox_image, "glossia-local:dev")

    args =
      [
        "create",
        "--name",
        name,
        "--cpus",
        to_string(configured(:microsandbox_cpus, 2)),
        "--memory",
        configured(:microsandbox_memory, "2G"),
        "--mkdir",
        configured(:microsandbox_repo_path, "/tmp/glossia/repo"),
        "--max-duration",
        max_duration(params),
        "--init",
        "/bin/sleep",
        "--init-arg",
        "infinity"
      ] ++ mount_args() ++ [image]

    case msb(args, timeout: boot_timeout()) do
      {_, 0} ->
        case prepare_workspace(sandbox_id) do
          :ok ->
            {:ok, sandbox_id}

          {:error, reason} ->
            _ = delete(sandbox_id)
            {:error, reason}
        end

      {output, status} ->
        {:error, {:microsandbox_create_failed, status, output}}
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
    args = ["exec", "--no-tty"] ++ exec_opts(opts) ++ [sandbox_name(sandbox_id), "--"] ++ argv
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

      {output, _status} when is_binary(output) ->
        if sandbox_not_found?(output) do
          {:error, :not_found}
        else
          delete_running(name)
        end
    end
  end

  defp delete_running(name) do
    case msb(["stop", name], timeout: 30_000) do
      {output, _status} when is_binary(output) and output != "" ->
        if sandbox_not_found?(output) do
          {:error, :not_found}
        else
          remove_stopped(name)
        end

      _ ->
        remove_stopped(name)
    end
  end

  defp remove_stopped(name) do
    case msb(["rm", name], timeout: 30_000) do
      {_, 0} ->
        :ok

      {output, status} ->
        if sandbox_not_found?(output) do
          {:error, :not_found}
        else
          {:error, {:microsandbox_delete_failed, status, output}}
        end
    end
  end

  defp sandbox_not_found?(output) when is_binary(output) do
    String.contains?(String.downcase(output), "sandbox not found")
  end

  defp sandbox_not_found?(_output), do: false

  @impl true
  def download_file(sandbox_id, path) when is_binary(path) do
    with {:ok, path} <- safe_workspace_path(sandbox_id, path) do
      copy_file_from_sandbox(sandbox_id, path)
    end
  end

  @impl true
  def upload_file(sandbox_id, path, content) when is_binary(path) and is_binary(content) do
    with {:ok, path} <- safe_workspace_path(sandbox_id, path) do
      with {:ok, %{"exitCode" => 0}} <-
             execute_argv(sandbox_id, ["mkdir", "-p", "--", Path.dirname(path)], []),
           :ok <- copy_file_to_sandbox(sandbox_id, path, content) do
        :ok
      else
        {:ok, result} -> {:error, {:write_failed, result}}
        {:error, _reason} = error -> error
      end
    end
  end

  @impl true
  def delete_file(sandbox_id, path) when is_binary(path) do
    with {:ok, path} <- safe_workspace_path(sandbox_id, path) do
      case execute_argv(sandbox_id, ["rm", "-rf", "--", path], []) do
        {:ok, %{"exitCode" => 0}} -> :ok
        {:ok, result} -> {:error, {:delete_failed, result}}
      end
    end
  end

  @impl true
  def repo_path(_sandbox_id), do: {:ok, configured(:microsandbox_repo_path, "/tmp/glossia/repo")}

  @impl true
  def start_agent_session(sandbox_id, caller, opts) when is_pid(caller) do
    Task.start(fn -> run_agent_session(sandbox_id, caller, opts) end)
  end

  defp run_agent_session(sandbox_id, caller, opts) do
    timeout_ms = Keyword.get(opts, :timeout_ms, 660_000)

    with {:ok, repo_path} <- repo_path(sandbox_id),
         :ok <- upload_job(sandbox_id, repo_path, opts),
         {:ok, poller} <- start_job_event_poller(sandbox_id, caller) do
      result =
        try do
          execute_setup_job(sandbox_id, timeout_ms + 30_000)
        rescue
          error -> {:error, Exception.message(error)}
        after
          Glossia.Sandbox.HarnessEventPoller.stop(poller)
          _ = delete_file(sandbox_id, setup_job_path())
          _ = delete_file(sandbox_id, setup_job_event_path())
        end

      case result do
        {:ok, %{"exitCode" => 0}} -> send(caller, {:agent_done, :completed})
        error -> send_agent_failure(caller, error)
      end
    else
      error -> send_agent_failure(caller, error)
    end
  end

  defp send_agent_failure(caller, reason) do
    send(caller, {
      :agent_event,
      %{
        "event_type" => "error",
        "content" => "The isolated setup process stopped before it completed.",
        "metadata" => %{"reason" => inspect(reason)}
      }
    })

    send(caller, {:agent_done, :failed})
  end

  defp upload_job(sandbox_id, repo_path, opts) do
    job = %{
      "repo_path" => repo_path,
      "event_path" => setup_job_event_path(),
      "repository" => Keyword.fetch!(opts, :repository),
      "target_languages" => Keyword.get(opts, :target_languages, []),
      "harness" => Keyword.get(opts, :harness, %{}),
      "timeout_ms" => Keyword.get(opts, :timeout_ms, 660_000)
    }

    upload_file(sandbox_id, setup_job_path(), JSON.encode!(job))
  end

  defp start_job_event_poller(sandbox_id, caller) do
    Glossia.Sandbox.HarnessEventPoller.start(
      fn path -> download_file(sandbox_id, path) end,
      caller,
      setup_job_event_path()
    )
  end

  defp execute_setup_job(sandbox_id, timeout_ms) do
    execute_argv(
      sandbox_id,
      [
        "/app/bin/glossia",
        "eval",
        "{:ok, _} = Application.ensure_all_started(:glossia); Glossia.Projects.SetupSandboxJob.run!(System.fetch_env!(\"GLOSSIA_SETUP_JOB_PATH\"))"
      ],
      env: %{
        "GLOSSIA_ISOLATED_CHILD" => "true",
        "GLOSSIA_SETUP_JOB_PATH" => setup_job_path()
      },
      timeout_ms: timeout_ms,
      output_limit_bytes: 256_000
    )
  end

  defp setup_job_path, do: "/tmp/glossia/setup-job.json"
  defp setup_job_event_path, do: "/tmp/glossia/setup-job-events.jsonl"

  defp prepare_workspace(sandbox_id) do
    with {:ok, repo_path} <- repo_path(sandbox_id),
         {_, 0} <-
           msb(
             [
               "exec",
               "--no-tty",
               "--user",
               "root",
               sandbox_name(sandbox_id),
               "--",
               "sh",
               "-c",
               "mkdir -p \"$1\" && chown -R nobody:nogroup \"$2\"",
               "sh",
               repo_path,
               Path.dirname(repo_path)
             ],
             timeout: 30_000
           ) do
      :ok
    else
      {:error, _reason} = error -> error
      {output, status} -> {:error, {:repo_path_failed, status, output}}
    end
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
        with {:ok, cwd} <- safe_workspace_path(sandbox_id, cwd) do
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
        boundary =
          if expanded == repo_path or String.starts_with?(expanded, repo_path <> "/"),
            do: repo_path,
            else: root

        {:ok, expanded, boundary}
      else
        {:error, :path_outside_sandbox}
      end
    end
  end

  defp safe_workspace_path(sandbox_id, path) do
    with {:ok, expanded, boundary} <- workspace_path(sandbox_id, path),
         {:ok, %{"exitCode" => 0, "stdout" => output}} <-
           execute_argv(sandbox_id, ["realpath", "-m", "-z", "--", expanded],
             timeout_ms: 30_000,
             output_limit_bytes: 8_192
           ),
         {:ok, resolved} <- decode_realpath(output),
         true <- resolved == expanded and inside_path?(resolved, boundary) do
      {:ok, resolved}
    else
      false -> {:error, :path_outside_sandbox}
      {:ok, result} -> {:error, {:path_resolution_failed, result}}
      {:error, _reason} = error -> error
    end
  end

  defp decode_realpath(output) when is_binary(output) do
    case String.split(output, <<0>>, trim: true) do
      [path] when path != "" -> {:ok, path}
      _ -> {:error, :invalid_resolved_path}
    end
  end

  defp inside_path?(path, boundary) do
    path == boundary or String.starts_with?(path, boundary <> "/")
  end

  defp msb(args, opts) do
    command = configured(:microsandbox_command, "msb")

    MuonTrap.cmd("sh", ["-c", ~s(exec "$@" </dev/null), "msb", command | args],
      timeout: Keyword.get(opts, :timeout, 120_000),
      stderr_to_stdout: true,
      into: ""
    )
  rescue
    error in ErlangError ->
      {Exception.message(error), 127}
  end

  defp configured(key, default), do: Glossia.Sandbox.configured(key, default)

  defp copy_file_to_sandbox(sandbox_id, destination, content) do
    with_private_transfer_dir(fn dir ->
      source = Path.join(dir, "payload")

      with :ok <- write_private_file(source, content),
           {_, 0} <-
             msb(
               ["copy", "--quiet", source, "#{sandbox_name(sandbox_id)}:#{destination}"],
               timeout: 120_000
             ),
           :ok <- secure_guest_file(sandbox_id, destination) do
        :ok
      else
        {:error, reason} -> {:error, reason}
        {output, status} -> {:error, {:microsandbox_copy_failed, status, output}}
      end
    end)
  end

  defp copy_file_from_sandbox(sandbox_id, source) do
    with_private_transfer_dir(fn dir ->
      destination = Path.join(dir, "payload")

      case msb(
             ["copy", "--quiet", "#{sandbox_name(sandbox_id)}:#{source}", destination],
             timeout: 120_000
           ) do
        {_, 0} -> read_transferred_file(destination)
        {output, status} -> {:error, {:microsandbox_copy_failed, status, output}}
      end
    end)
  end

  defp read_transferred_file(path) do
    limit = configured(:file_transfer_limit_bytes, 16_777_216)

    with {:ok, %{type: :regular, size: size}} <- File.stat(path),
         true <- size <= limit,
         {:ok, content} <- File.read(path) do
      {:ok, content}
    else
      false -> {:error, {:file_too_large, limit}}
      {:ok, %{type: type}} -> {:error, {:invalid_file_type, type}}
      {:error, _reason} = error -> error
    end
  end

  defp with_private_transfer_dir(callback) when is_function(callback, 1) do
    temp_root = Path.expand(System.tmp_dir!())
    template = Path.join(temp_root, "glossia-sandbox-transfer.XXXXXXXXXX")

    case MuonTrap.cmd("mktemp", ["-d", template],
           timeout: 30_000,
           stderr_to_stdout: true,
           into: ""
         ) do
      {output, 0} ->
        dir = String.trim(output)

        if dir != "" and inside_path?(dir, temp_root) and File.dir?(dir) do
          try do
            with :ok <- File.chmod(dir, 0o700), do: callback.(dir)
          after
            File.rm_rf(dir)
          end
        else
          {:error, :invalid_temporary_directory}
        end

      {output, status} ->
        {:error, {:temporary_directory_failed, status, output}}
    end
  end

  defp write_private_file(path, content) do
    case File.open(path, [:write, :binary, :exclusive]) do
      {:ok, io} ->
        try do
          with :ok <- File.chmod(path, 0o600),
               :ok <- IO.binwrite(io, content),
               :ok <- :file.sync(io) do
            :ok
          end
        after
          File.close(io)
        end

      {:error, _reason} = error ->
        error
    end
  end

  defp secure_guest_file(sandbox_id, path) do
    case msb(
           [
             "exec",
             "--no-tty",
             "--user",
             "root",
             sandbox_name(sandbox_id),
             "--",
             "sh",
             "-c",
             "chown nobody:nogroup \"$1\" && chmod 600 \"$1\"",
             "sh",
             path
           ],
           timeout: 30_000
         ) do
      {_, 0} -> :ok
      {output, status} -> {:error, {:microsandbox_permissions_failed, status, output}}
    end
  end

  defp mount_args do
    configured(:microsandbox_mounts, [])
    |> Enum.flat_map(fn mount ->
      source = mount[:source] || mount["source"]
      destination = mount[:destination] || mount["destination"]
      read_only = mount[:read_only] || mount["read_only"]

      if is_binary(source) and source != "" and is_binary(destination) and destination != "" do
        suffix = if read_only, do: ":ro", else: ""
        ["--mount-dir", "#{Path.expand(source)}:#{destination}#{suffix}"]
      else
        []
      end
    end)
  end

  defp boot_timeout do
    :glossia
    |> Application.get_env(:flame, [])
    |> Keyword.get(:boot_timeout, 120_000)
  end

  defp max_duration(params) do
    seconds =
      case params[:deadline_at] || params["deadline_at"] do
        %DateTime{} = deadline -> max(DateTime.diff(deadline, DateTime.utc_now(), :second), 1)
        _ -> configured(:default_ttl_seconds, 3600)
      end

    "#{seconds}s"
  end

  defp sandbox_name(sandbox_id) do
    "glossia-" <> String.replace(sandbox_id, "-", "")
  end

  defp truncate(output, limit) when byte_size(output) > limit do
    binary_part(output, 0, limit)
  end

  defp truncate(output, _limit), do: output
end
