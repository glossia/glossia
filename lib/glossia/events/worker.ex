defmodule Glossia.Events.Worker do
  @moduledoc """
  It processes the events that are triggered by the version control system.
  """

  # Modules
  require Logger
  alias Glossia.Events.GitEvent
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
    case Repo.get_by(GitEvent, git_commit_sha: git_commit_sha, project_id: project_id) do
      nil ->
        trigger_build(%{
          git_access_token: git_access_token,
          event: event,
          git_default_branch: git_default_branch,
          git_ref: git_ref,
          git_commit_sha: git_commit_sha,
          vcs_id: vcs_id,
          vcs_platform: vcs_platform,
          project_id: project_id
        })

      %GitEvent{} ->
        :ok
    end
  end

  def trigger_build(
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
    git_event =
      Repo.insert!(GitEvent.changeset(%GitEvent{}, attrs))

    attrs |> update_commit_status(:translating)

    Glossia.Builds.run(
      env: %{
        GLOSSIA_GIT_REF: git_ref,
        GLOSSIA_GIT_DEFAULT_BRANCH: git_default_branch,
        GLOSSIA_VCS_ID: vcs_id,
        GLOSSIA_VCS_PLATFORM: vcs_platform,
        GLOSSIA_GIT_COMMIT_SHA: git_commit_sha,
        GLOSSIA_GIT_EVENT_ID: git_event.id,
        GLOSSIA_EVENT: event,
        GLOSSIA_GIT_ACCESS_TOKEN: git_access_token
      },
      update_status_cb: fn vm_id, status ->
        update_git_event_status(git_event: git_event, vm_id: vm_id, status: status)
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

  defp update_git_event_status(git_event: git_event, vm_id: vm_id, status: status) do
    {:ok, _} =
      git_event |> GitEvent.changeset(%{vm_id: vm_id, status: status}) |> Repo.update()
  end
end
