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

  def run_remotely(command: command, logs_path: _, env: env) do
    # https://cloud.google.com/build/docs/api/reference/rest/v1/projects.builds/create
    # https://github.com/googleapis/elixir-google-api/blob/main/clients/cloud_build/lib/google_api/cloud_build/v1/api/projects.ex#L213
    project_id = Application.get_env(:glossia, :secrets)[:google_cloud_project_id]

    {:ok, token} = Goth.fetch(Glossia.Goth)

    {:ok, operation} =
      GoogleApi.CloudBuild.V1.Connection.new(token.token)
      |> GoogleApi.CloudBuild.V1.Api.Projects.cloudbuild_projects_builds_create(
        project_id,
        body: %GoogleApi.CloudBuild.V1.Model.Build{
          timeout: "#{@timeout}",
          steps: [
            %GoogleApi.CloudBuild.V1.Model.BuildStep{
              name: docker_image(),
              args: deno_arguments(command: command, env: env),
              env:
                docker_env_variables()
                |> Enum.reduce([], fn {k, v}, acc -> ["#{k}=#{v}" | acc] end)
            }
          ]
        }
      )

    dbg(operation)
  end

  def run_locally(command: command, logs_path: logs_path, env: env) do
    docker_env_flags =
      docker_env_variables()
      |> Enum.into(env)
      |> Enum.reduce([], fn {k, v}, acc ->
        ["--env", "#{Atom.to_string(k)}=#{v}" | acc]
      end)

    arguments =
      ["/usr/bin/env", "docker", "run"] ++
        ["--init"] ++
        ["--volume", builder_directory() <> ":" <> "/builder"] ++
        ["--workdir", "/builder"] ++
        ["--publish", "4000:4000"] ++
        docker_env_flags ++
        [docker_image()] ++
        deno_arguments(command: command, env: env)

    logs_path = File.cwd!() |> Path.join(["/tmp/logs", logs_path])
    logs_path |> Path.dirname() |> File.mkdir_p!()

    Exile.stream!(arguments, exit_timeout: @timeout)
    |> Stream.into(File.stream!(logs_path))
    |> Stream.run()
  end

  @spec docker_env_variables() :: map()
  def docker_env_variables() do
    %{
      GLOSSIA_URL: Application.get_env(:glossia, :url),
      GLOSSIA_APP_SIGNAL_API_KEY:
        Application.get_env(:glossia, :secrets)[:app_signal_builder_api_key]
    }
  end

  def deno_arguments(command: command, env: env) do
    path =
      if Application.get_env(:glossia, :env) == :prod do
        Application.get_env(:glossia, :url) <> "/builder/index.ts"
      else
        "./index.ts"
      end

    ["run", "--allow-net", "--allow-env=#{Enum.join(deno_allow_env_variables(env), ",")}"] ++
      [path, command]
  end

  def docker_image() do
    "denoland/deno:" <> Application.get_env(:glossia, :versions)[:deno]
  end

  def deno_allow_env_variables(env) do
    Enum.reduce(env, [], fn {k, v}, acc ->
      [Atom.to_string(k) | acc]
    end) ++ ["GLOSSIA_URL", "GLOSSIA_APP_SIGNAL_API_KEY"]
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
