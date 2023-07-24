defmodule Glossia.VM.Builder do
  @moduledoc """
  This module provides utilities for running the builder executable using Docker in development
  and a virtualization solution by cloud providers in the case of production.
  """
  require Logger

  @timeout 60 * 3

  def run(command: command, logs_path: logs_path, env: env) do
    if Application.get_env(:glossia, :env) == :prod do
      run_remotely(command: command, logs_path: logs_path, env: env)
    else
      run_locally(command: command, logs_path: logs_path, env: env)
    end
  end

  def run_remotely(command: _, logs_path: _, env: _) do
    # Not implemented yet
  end

  def run_locally(command: command, logs_path: logs_path, env: env) do
    docker_env_flags =
      Enum.reduce(env, [], fn {k, v}, acc ->
        ["--env", "#{Atom.to_string(k)}=#{v}" | acc]
      end)

    arguments =
      ["/usr/bin/env", "docker", "run"] ++
        ["--init"] ++
        ["--volume", builder_directory() <> ":" <> "/builder"] ++
        ["--workdir", "/builder"] ++
        ["--publish", "4000:4000"] ++
        docker_env_flags ++
        ["--env", "GLOSSIA_URL=" <> "http://127.0.0.1:4000"] ++
        ["denoland/deno:" <> Application.get_env(:glossia, :versions)[:deno]] ++
        default_deno_arguments() ++
        ["--allow-env=#{Enum.join(deno_allow_env_variables(env), ",")}"] ++
        ["./index.ts", command]

    logs_path = File.cwd!() |> Path.join(["/tmp/logs", logs_path])
    logs_path |> Path.dirname() |> File.mkdir_p!()

    Exile.stream!(arguments, exit_timeout: @timeout)
    |> Stream.into(File.stream!(logs_path))
    |> Stream.run()
  end

  def deno_allow_env_variables(env) do
    Enum.reduce(env, [], fn {k, v}, acc ->
      [Atom.to_string(k) | acc]
    end) ++ ["GLOSSIA_URL"]
  end

  def default_deno_arguments do
    ["run", "--allow-net"]
  end

  def builder_directory() do
    app_dir = Application.app_dir(:glossia)
    Path.join([app_dir, "priv", "static", "builder"])
  end

  def docker_available?() do
    case Exile.stream(["/usr/bin/env", "which", "docker"]) |> Enum.to_list() do
      [_, {:exit, {:status, 0}}] -> true
      _ -> false
    end
  end
end
