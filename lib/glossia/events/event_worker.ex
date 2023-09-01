defmodule Glossia.Events.EventWorker do
  @moduledoc """
  It processes the events that are triggered by the version control system.
  """

  # Modules
  require Logger
  alias Glossia.Events.Event
  alias Glossia.Repo
  use Oban.Worker
  alias Glossia.Foundation.ContentSources.Core, as: ContentSources

  # Impl: Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "access_token" => access_token,
          "content_source_access_token" => content_source_access_token,
          "project_id" => project_id,
          "type" => type,
          "version" => version,
          "content_source_id" => content_source_id,
          "content_source_platform" => content_source_platform,
          "project_handle" => project_handle,
          "account_handle" => account_handle
        }
      }) do
    git_event = Repo.get_by(Event, version: version, project_id: project_id)

    case git_event do
      nil ->
        trigger_build(%{
          access_token: access_token,
          type: type,
          version: version,
          project_id: project_id,
          project_handle: project_handle,
          account_handle: account_handle,
          content_source_id: content_source_id,
          content_source_platform: content_source_platform,
          content_source_access_token: content_source_access_token
        })

      %Event{} ->
        :ok
    end
  end

  def trigger_build(
        %{
          content_source_id: content_source_id,
          content_source_platform: content_source_platform,
          version: version,
          access_token: access_token,
          content_source_access_token: content_source_access_token,
          project_id: _project_id,
          project_handle: project_handle,
          account_handle: account_handle
        } = attrs
      ) do
    event =
      Repo.insert!(Event.changeset(%Event{}, attrs))

    content_source =
      ContentSources.new(String.to_atom(content_source_platform), content_source_id)

    ContentSources.update_state(
      content_source,
      :pending,
      version,
      target_url: "",
      description: "Localizing"
    )

    Glossia.Builds.run(%{
      env: %{
        # Project
        GLOSSIA_ACCESS_TOKEN: access_token,
        GLOSSIA_OWNER_HANDLE: account_handle,
        GLOSSIA_PROJECT_HANDLE: project_handle,

        # Event
        GLOSSIA_EVENT_TYPE: event.type,
        GLOSSIA_EVENT_ID: event.id,
        GLOSSIA_EVENT_VERSION: event.version,

        # Content Source
        GLOSSIA_CONTENT_SOURCE_ID: content_source_id,
        GLOSSIA_CONTENT_SOURCE_PLATFORM: content_source_platform,
        GLOSSIA_CONTENT_SOURCE_ACCESS_TOKEN: content_source_access_token
      },
      update_status_cb: fn %{
                             vm_id: vm_id,
                             status: status,
                             vm_logs_url: vm_logs_url,
                             markdown_error_message: markdown_error_message
                           } ->
        update_event_status(%{
          event: event,
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
      version,
      target_url: "",
      description: "Localized"
    )

    :ok
  end

  defp update_event_status(%{
         event: event,
         vm_id: vm_id,
         status: status,
         vm_logs_url: vm_logs_url,
         markdown_error_message: markdown_error_message
       }) do
    {:ok, _} =
      event
      |> Event.changeset(%{
        vm_id: vm_id,
        vm_logs_url: vm_logs_url,
        status: status,
        markdown_error_message: markdown_error_message
      })
      |> Repo.update()
  end
end
