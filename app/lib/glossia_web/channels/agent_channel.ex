defmodule GlossiaWeb.AgentChannel do
  @moduledoc false

  use GlossiaWeb, :channel

  require Logger

  alias Glossia.Ingestion
  alias Glossia.Projects
  alias Glossia.Translations

  @impl true
  def join("agent:setup:" <> project_id, _payload, socket) do
    if project_id == socket.assigns.project_id do
      project = Glossia.Repo.get(Glossia.Accounts.Project, project_id)

      if project do
        {:ok, assign(socket, project: project, mode: :setup)}
      else
        {:error, %{reason: "project_not_found"}}
      end
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def join("agent:translate:" <> translation_id, _payload, socket) do
    translation = Glossia.Repo.get(Translations.Translation, translation_id)

    if translation && to_string(translation.project_id) == socket.assigns.project_id do
      {:ok, assign(socket, translation: translation, mode: :translate)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("event", payload, socket) do
    sequence = payload["sequence"] || 0
    event_type = payload["event_type"] || "unknown"
    content = payload["content"] || ""
    metadata = payload["metadata"] || "{}"

    event_data = %{
      sequence: sequence,
      event_type: event_type,
      content: content,
      metadata: metadata
    }

    case socket.assigns.mode do
      :translate ->
        translation = socket.assigns.translation

        Ingestion.record_translation_event(
          translation.id,
          sequence,
          event_type,
          content,
          metadata
        )

        Translations.broadcast_translation_event(translation, event_data)

      :setup ->
        project = socket.assigns.project

        Ingestion.record_setup_event(
          project.id,
          sequence,
          event_type,
          content,
          metadata
        )

        Projects.broadcast_setup_event(project, event_data)
    end

    {:reply, :ok, socket}
  end
end
