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
          "vcs_id" => vcs_id,
          "vcs_platform" => vcs_platform
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
          vcs_id: vcs_id,
          vcs_platform: vcs_platform,
          project_id: project_id
        })

      %Build{} ->
        :ok
    end
  end

  def build(
        %{
          event: event,
          vcs_id: vcs_id,
          vcs_platform: vcs_platform,
          git_ref: git_ref,
          git_commit_sha: git_commit_sha,
          git_default_branch: git_default_branch,
          git_access_token: git_access_token
        } = attrs
      ) do
    build =
      Repo.insert!(Build.changeset(%Build{}, attrs))

    attrs |> update_commit_status(:translating)

    Glossia.Builds.VirtualMachine.run(
      env: %{
        GLOSSIA_GIT_REF: git_ref,
        GLOSSIA_GIT_DEFAULT_BRANCH: git_default_branch,
        GLOSSIA_VCS_ID: vcs_id,
        GLOSSIA_VCS_PLATFORM: vcs_platform,
        GLOSSIA_GIT_COMMIT_SHA: git_commit_sha,
        GLOSSIA_BUILD_ID: build.id,
        GLOSSIA_EVENT: event,
        GLOSSIA_GIT_ACCESS_TOKEN: git_access_token
      },
      status_update_cb: fn build_id, status ->
        update_build_status(build: build, build_id: build_id, status: status)
      end
    )

    attrs |> update_commit_status(:translated)

    :ok
  end

  defp update_commit_status(attrs, :translating) do
    attrs
    |> Map.put_new(:state, "pending")
    |> Map.put_new(:description, "Translating")
    |> update_commit_status()
  end

  defp update_commit_status(attrs, :translated) do
    attrs
    |> Map.put_new(:state, "success")
    |> Map.put_new(:description, "Translated")
    |> update_commit_status()
  end

  def update_commit_status(attrs) do
    context = Application.get_env(:glossia, :env) |> get_commit_status_context_for_env()

    attrs
    |> Map.put_new(:target_url, "")
    |> Map.put_new(:context, context)
    |> Glossia.VersionControl.create_commit_status()

    # Glossia.VersionControl.create_commit_status(
    #   vcs_platform: vcs_platform,
    #   commit_sha: git_commit_sha,
    #   vcs_id: vcs_id,
    #   state: state,
    #   target_url: "https://glossia.ai",
    #   context: context,
    #   description: description
    # )
  end

  def get_commit_status_context_for_env(:prod) do
    "Glossia"
  end

  def get_commit_status_context_for_env(_) do
    "Glossia (Dev)"
  end

  defp update_build_status(build: build, build_id: build_id, status: status) do
    {:ok, _} =
      build |> Build.changeset(%{build_id: build_id, status: status}) |> Repo.update()
  end
end
