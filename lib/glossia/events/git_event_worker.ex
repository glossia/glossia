defmodule Glossia.Events.GitEventWorker do
  @moduledoc """
  It processes the events that are triggered by the version control system.
  """

  # Modules
  require Logger
  alias Glossia.Events.GitEvent
  alias Glossia.Repo
  use Oban.Worker
  alias Glossia.Foundation.ContentSources.Core, as: ContentSources

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
          "content_source_id" => content_source_id,
          "content_source_platform" => content_source_platform,
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
          content_source_id: content_source_id,
          content_source_platform: content_source_platform,
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
          content_source_id: content_source_id,
          content_source_platform: content_source_platform,
          ref: ref,
          commit_sha: commit_sha,
          default_branch: default_branch,
          access_token: access_token,
          git_access_token: git_access_token,
          project_id: _project_id,
          project_handle: project_handle,
          account_handle: account_handle
        } = attrs
      ) do
    git_event =
      Repo.insert!(GitEvent.changeset(%GitEvent{}, attrs))

    content_source =
      ContentSources.new(String.to_atom(content_source_platform), content_source_id)

    ContentSources.update_state(
      content_source,
      :pending,
      commit_sha,
      target_url: "",
      description: "Localizing"
    )

    Glossia.Builds.run(%{
      env: %{
        # Event
        GLOSSIA_EVENT: "git" <> "_" <> event,
        GLOSSIA_ACCESS_TOKEN: access_token,
        GLOSSIA_OWNER_HANDLE: account_handle,
        GLOSSIA_PROJECT_HANDLE: project_handle,

        # Content Source
        GLOSSIA_CONTENT_SOURCE_ID: content_source_id,
        GLOSSIA_CONTENT_SOURCE_PLATFORM: content_source_platform,

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

    ContentSources.update_state(
      content_source,
      :success,
      commit_sha,
      target_url: "",
      description: "Localized"
    )

    :ok
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
