defmodule Glossia.Builds.VM do
  @moduledoc """
  This module provides utilities for running the builder executable using Docker in development
  and a virtualization solution by cloud providers in the case of production.
  """
  require Logger

  @timeout 60 * 3

  @spec run(
          attrs :: [
            env: map(),
            status_update_cb: (String.t(), atom() -> nil)
          ]
        ) ::
          {:ok, String.t()}
  def run(env: env, status_update_cb: status_update_cb) do
    if Application.get_env(:glossia, :env) == :prod do
      run_using_google_cloud_build(env: env, status_update_cb: status_update_cb)
    else
      run_using_docker(env: env, status_update_cb: status_update_cb)
    end
  end

  defp run_using_google_cloud_build(
         env: env,
         status_update_cb: status_update_cb
       ) do
    # https://cloud.google.com/build/docs/api/reference/rest/v1/projects.builds/create
    # https://github.com/googleapis/elixir-google-api/blob/main/clients/cloud_build/lib/google_api/cloud_build/v1/api/projects.ex#L213
    project_id = Application.get_env(:glossia, :google_cloud_project_id)

    {:ok, token} = Goth.fetch(Glossia.Goth)

    {:ok, %GoogleApi.CloudBuild.V1.Model.Operation{metadata: %{"build" => build}}} =
      GoogleApi.CloudBuild.V1.Connection.new(token.token)
      |> GoogleApi.CloudBuild.V1.Api.Projects.cloudbuild_projects_builds_create(
        project_id,
        body: %GoogleApi.CloudBuild.V1.Model.Build{
          timeout: "#{@timeout}s",
          steps: [
            %GoogleApi.CloudBuild.V1.Model.BuildStep{
              name: get_docker_image(),
              args: get_deno_args(env: env),
              env:
                env
                |> Enum.into(get_docker_env_variables())
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

  defp monitor_google_cloud_build(
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

  defp run_using_docker(env: env, status_update_cb: status_update_cb) do
    docker_env_flags =
      get_docker_env_variables()
      |> Enum.into(env)
      |> Enum.reduce([], fn {k, v}, acc ->
        ["--env", "#{Atom.to_string(k)}=#{v}" | acc]
      end)

    arguments =
      ["docker", "run"] ++
        ["--init"] ++
        ["--volume", get_builder_directory() <> ":" <> "/builder"] ++
        ["--workdir", "/builder"] ++
        ["--publish", "4000:4000"] ++
        docker_env_flags ++
        [get_docker_image()] ++
        get_deno_args(env: env)

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

  @spec get_docker_env_variables() :: map()
  defp get_docker_env_variables() do
    %{
      GLOSSIA_URL: Application.get_env(:glossia, :url),
      GLOSSIA_API_KEY: Application.get_env(:glossia, :builder_api_key),
      GLOSSIA_APP_SIGNAL_API_KEY: Application.get_env(:glossia, :app_signal_builder_api_key)
    }
  end

  @spec get_deno_args(attrs :: [env: map()]) :: [String.t()]
  defp get_deno_args(env: env) do
    path =
      if Application.get_env(:glossia, :env) == :prod do
        Application.get_env(:glossia, :url) <> "/builder/index.ts"
      else
        "./index.ts"
      end

    deno_allow_env_flags =
      (Enum.reduce(env, [], fn {k, _}, acc ->
         [Atom.to_string(k) | acc]
       end) ++ ["GLOSSIA_URL", "GLOSSIA_APP_SIGNAL_API_KEY", "GLOSSIA_API_KEY"])
      |> Enum.join(",")

    [
      "run",
      "--allow-net",
      "--allow-run",
      "--allow-env=#{deno_allow_env_flags}",
      path
    ]
  end

  @doc """
  It returns the Docker image to use for the builder.
  """
  @spec get_docker_image() :: String.t()
  def get_docker_image() do
    "denoland/deno:" <> Application.get_env(:glossia, :versions)[:deno]
  end

  @doc """
  It returns the directory where the builder executable is located.
  This is necessary when running local builds using Docker to mount the
  builder directory and run the executable.
  """
  @spec get_builder_directory() :: String.t()
  def get_builder_directory() do
    app_dir = Application.app_dir(:glossia)
    Path.join([app_dir, "priv", "static", "builder"])
  end

  @doc """
  It returns true if Docker is available in the system.
  """
  @spec docker_available?() :: boolean()
  def docker_available?() do
    case Rambo.run("/usr/bin/env", ["which", "docker"], log: false) do
      {:ok, _} -> true
      _ -> false
    end
  end
end
