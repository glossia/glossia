defmodule Glossia.Builds.Worker do
  @moduledoc """
  A translate build represents a translation job that's being run in a virtualized environment.
  Locally we use Docker when present, and in production we use Google Cloud Build.
  """

  # Modules
  require Logger
  alias Glossia.Builds.Build
  alias Glossia.Repo
  use Oban.Worker

  # Impl: Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "git_access_token" => git_access_token,
          "project_id" => project_id,
          "event" => event,
          "git_default_branch" => git_default_branch,
          "git_ref" => git_ref,
          "git_commit_sha" => git_commit_sha,
          "git_repository_id" => git_repository_id,
          "git_vcs" => git_vcs
        }
      }) do
    case Repo.get_by(Build, git_commit_sha: git_commit_sha, project_id: project_id) do
      nil ->
        build(%{
          git_access_token: git_access_token,
          event: event,
          git_default_branch: git_default_branch,
          git_ref: git_ref,
          git_commit_sha: git_commit_sha,
          git_repository_id: git_repository_id,
          git_vcs: git_vcs,
          project_id: project_id
        })

      %Build{} ->
        :ok
    end
  end

  def build(%{
        git_access_token: git_access_token,
        event: event,
        git_commit_sha: git_commit_sha,
        git_repository_id: git_repository_id,
        git_vcs: git_vcs,
        git_ref: git_ref,
        git_default_branch: git_default_branch,
        project_id: project_id
      }) do
    build =
      Repo.insert!(
        Build.changeset(%Build{}, %{
          git_commit_sha: git_commit_sha,
          project_id: project_id,
          git_repository_id: git_repository_id,
          git_vcs: git_vcs,
          event: event
        })
      )

    commit_status_attrs = [
      git_commit_sha: git_commit_sha,
      git_repository_id: git_repository_id,
      git_vcs: git_vcs
    ]

    commit_status_attrs
    |> Keyword.put_new(:state, "pending")
    |> Keyword.put_new(:description, "Translating")
    |> create_commit_status()

    Glossia.Builds.VM.run(
      command: "translate",
      env: %{
        GLOSSIA_GIT_REF: git_ref,
        GLOSSIA_GIT_DEFAULT_BRANCH: git_default_branch,
        GLOSSIA_GIT_REPOSITORY_ID: git_repository_id,
        GLOSSIA_GIT_REPOSITORY_VCS: git_vcs,
        GLOSSIA_GIT_COMMIT_SHA: git_commit_sha,
        GLOSSIA_BUILD_ID: build.id,
        GLOSSIA_EVENT: event,
        GLOSSIA_GIT_ACCESS_TOKEN: git_access_token
      },
      status_update_cb: fn build_id, status ->
        update_build_status(build: build, build_id: build_id, status: status)
      end
    )

    commit_status_attrs
    |> Keyword.put_new(:state, "success")
    |> Keyword.put_new(:description, "Translated")
    |> create_commit_status()

    :ok
  end

  defp update_build_status(build: build, build_id: build_id, status: status) do
    {:ok, _} =
      build |> Build.changeset(%{build_id: build_id, status: status}) |> Repo.update()
  end

  defp create_commit_status(
         description: description,
         state: state,
         git_commit_sha: git_commit_sha,
         git_repository_id: git_repository_id,
         git_vcs: git_vcs
       ) do
    context =
      case Application.get_env(:glossia, :env) do
        :prod -> "Glossia"
        _ -> "Glossia (#{Application.get_env(:glossia, :env)})"
      end

    Glossia.VCS.create_commit_status(
      git_vcs: git_vcs,
      git_commit_sha: git_commit_sha,
      git_repository_id: git_repository_id,
      state: state,
      target_url: "https://glossia.ai",
      context: context,
      description: description
    )
  end
end
