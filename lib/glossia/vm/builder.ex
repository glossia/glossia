defmodule Glossia.VM.Builder do
  @moduledoc """
  This module provides utilities for running the builder executable using Docker in development
  and a virtualization solution by cloud providers in the case of production.
  """
  require Logger

  @timeout 60 * 3

  @spec run(
          attrs :: [
            command: String.t(),
            env: map(),
            status_update_cb: (String.t(), atom() -> nil)
          ]
        ) ::
          {:ok, String.t()}
  def run(command: command, env: env, status_update_cb: status_update_cb) do
    if Application.get_env(:glossia, :env) == :prod do
      run_in_google_cloud_build(command: command, env: env, status_update_cb: status_update_cb)
    else
      run_locally(command: command, env: env, status_update_cb: status_update_cb)
    end
  end

  defp run_in_google_cloud_build(command: command, env: env, status_update_cb: status_update_cb) do
    # https://cloud.google.com/build/docs/api/reference/rest/v1/projects.builds/create
    # https://github.com/googleapis/elixir-google-api/blob/main/clients/cloud_build/lib/google_api/cloud_build/v1/api/projects.ex#L213
    project_id = Application.get_env(:glossia, :secrets)[:google_cloud_project_id]

    {:ok, token} = Goth.fetch(Glossia.Goth)

    {:ok, %GoogleApi.CloudBuild.V1.Model.Operation{metadata: %{"build" => build}}} =
      GoogleApi.CloudBuild.V1.Connection.new(token.token)
      |> GoogleApi.CloudBuild.V1.Api.Projects.cloudbuild_projects_builds_create(
        project_id,
        body: %GoogleApi.CloudBuild.V1.Model.Build{
          timeout: "#{@timeout}s",
          steps: [
            %GoogleApi.CloudBuild.V1.Model.BuildStep{
              name: docker_image(),
              args: deno_arguments(command: command, env: env),
              env:
                env
                |> Enum.into(docker_env_variables())
                |> Enum.reduce([], fn {k, v}, acc -> ["#{k}=#{v}" | acc] end)
            }
          ]
        }
      )

    # https://cloud.google.com/build/docs/api/reference/rest/v1/projects.builds#status
    %{"id" => build_id, "status" => status, "projectId" => project_id} = build
    status = status |> String.downcase() |> String.to_atom()
    status_update_cb.(build_id, status)

    monitor_google_cloud_build(
      build_id: build_id,
      project_id: project_id,
      status_update_cb: status_update_cb
    )
  end

  def monitor_google_cloud_build(
        build_id: build_id,
        project_id: project_id,
        status_update_cb: status_update_cb
      ) do
    :timer.sleep(2000)
    {:ok, token} = Goth.fetch(Glossia.Goth)

    {:ok, %GoogleApi.CloudBuild.V1.Model.Build{} = build} =
      GoogleApi.CloudBuild.V1.Connection.new(token.token)
      |> GoogleApi.CloudBuild.V1.Api.Projects.cloudbuild_projects_builds_get(project_id, build_id)

    %{status: status} = build
    status = status |> String.downcase() |> String.to_atom()
    status_update_cb.(build_id, status)

    if [:status_unknown, :pending, :queued, :working] |> Enum.member?(status) do
      # The build is still running
      monitor_google_cloud_build(
        build_id: build_id,
        project_id: project_id,
        status_update_cb: status_update_cb
      )
    else
      :ok
    end
  end

  defp run_locally(command: command, env: env, status_update_cb: status_update_cb) do
    docker_env_flags =
      docker_env_variables()
      |> Enum.into(env)
      |> Enum.reduce([], fn {k, v}, acc ->
        ["--env", "#{Atom.to_string(k)}=#{v}" | acc]
      end)

    arguments =
      ["docker", "run"] ++
        ["--init"] ++
        ["--volume", builder_directory() <> ":" <> "/builder"] ++
        ["--workdir", "/builder"] ++
        ["--publish", "4000:4000"] ++
        docker_env_flags ++
        [docker_image()] ++
        deno_arguments(command: command, env: env)

    task =
      Task.async(fn ->
        Rambo.run("/usr/bin/env", arguments, log: &log_docker_output/1)
      end)

    status_update_cb.("#{task.pid}", :working)
    Task.await(task)
    status_update_cb.("#{task.pid}", :success)
    :ok
  end

  defp log_docker_output(output) do
    output
    |> String.split("\n")
    |> Enum.each(fn line ->
      Logger.info(line)
    end)
  end

  @spec docker_env_variables() :: map()
  defp docker_env_variables() do
    %{
      GLOSSIA_URL: Application.get_env(:glossia, :url),
      GLOSSIA_APP_SIGNAL_API_KEY:
        Application.get_env(:glossia, :secrets)[:app_signal_builder_api_key]
    }
  end

  @doc """
  It returns the arguments to pass to the `deno` executable.
  """
  @spec deno_arguments(attrs :: [command: String.t(), env: map()]) :: [String.t()]
  defp deno_arguments(command: command, env: env) do
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
    Enum.reduce(env, [], fn {k, _}, acc ->
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
