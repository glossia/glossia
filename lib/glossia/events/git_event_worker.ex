defmodule Glossia.Events.GitEventWorker do
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
          "access_token" => access_token,
          "git_access_token" => git_access_token,
          "project_id" => project_id,
          "event" => event,
          "default_branch" => default_branch,
          "ref" => ref,
          "commit_sha" => commit_sha,
          "vcs_id" => vcs_id,
          "vcs_platform" => vcs_platform,
          "project_handle" => project_handle,
          "account_handle" => account_handle
        }
      }) do
    git_event = Repo.get_by(GitEvent, commit_sha: commit_sha, project_id: project_id)

    case git_event do
      nil ->
        trigger_build(%{
          git_access_token: git_access_token,
          access_token: access_token,
          event: event,
          default_branch: default_branch,
          ref: ref,
          commit_sha: commit_sha,
          vcs_id: vcs_id,
          vcs_platform: vcs_platform,
          project_id: project_id,
          project_handle: project_handle,
          account_handle: account_handle
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
          ref: ref,
          commit_sha: commit_sha,
          default_branch: default_branch,
          access_token: access_token,
          git_access_token: git_access_token,
          project_id: _,
          project_handle: project_handle,
          account_handle: account_handle
        } = attrs
      ) do
    git_event =
      Repo.insert!(GitEvent.changeset(%GitEvent{}, attrs))

    attrs |> update_commit_status(:localizing)

    Glossia.Builds.run(%{
      env: %{
        # Event
        GLOSSIA_EVENT: "git" <> "_" <> event,
        GLOSSIA_ACCESS_TOKEN: access_token,
        GLOSSIA_OWNER_HANDLE: account_handle,
        GLOSSIA_PROJECT_HANDLE: project_handle,

        # VCS
        GLOSSIA_VCS_ID: vcs_id,
        GLOSSIA_VCS_PLATFORM: vcs_platform,

        # Git
        GLOSSIA_GIT_REF: ref,
        GLOSSIA_GIT_DEFAULT_BRANCH: default_branch,
        GLOSSIA_GIT_COMMIT_SHA: commit_sha,
        GLOSSIA_GIT_EVENT_ID: git_event.id,
        GLOSSIA_GIT_ACCESS_TOKEN: git_access_token
      },
      update_status_cb: fn %{
                             vm_id: vm_id,
                             status: status,
                             vm_logs_url: vm_logs_url,
                             markdown_error_message: markdown_error_message
                           } ->
        update_git_event_status(%{
          git_event: git_event,
          vm_id: vm_id,
          status: status,
          vm_logs_url: vm_logs_url,
          markdown_error_message: markdown_error_message
        })
      end
    })

    attrs |> update_commit_status(:localized)

    :ok
  end

  defp update_commit_status(attrs, :localizing) do
    attrs
    |> Map.put_new(:state, "pending")
    |> Map.put_new(:description, "Localizing")
    |> update_commit_status()
  end

  defp update_commit_status(attrs, :localized) do
    attrs
    |> Map.put_new(:state, "success")
    |> Map.put_new(:description, "Localized")
    |> update_commit_status()
  end

  def update_commit_status(attrs) do
    context = Application.get_env(:glossia, :env) |> get_commit_status_context_for_env()

    attrs
    |> Map.put_new(:target_url, "")
    |> Map.put_new(:context, context)
    |> Glossia.VersionControl.create_commit_status()
  end

  def get_commit_status_context_for_env(:prod) do
    "Glossia"
  end

  def get_commit_status_context_for_env(_) do
    "Glossia (Dev)"
  end

  defp update_git_event_status(%{
         git_event: git_event,
         vm_id: vm_id,
         status: status,
         vm_logs_url: vm_logs_url,
         markdown_error_message: markdown_error_message
       }) do
    {:ok, _} =
      git_event
      |> GitEvent.changeset(%{
        vm_id: vm_id,
        vm_logs_url: vm_logs_url,
        status: status,
        markdown_error_message: markdown_error_message
      })
      |> Repo.update()
  end
end
