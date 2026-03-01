defmodule GlossiaWeb.AgentChannel do
  @moduledoc false

  use GlossiaWeb, :channel

  require Logger

  alias Glossia.Ingestion
  alias Glossia.Projects

  @impl true
  def join("agent:setup:" <> project_id, _payload, socket) do
    if project_id == socket.assigns.project_id do
      project = Glossia.Repo.get(Glossia.Accounts.Project, project_id)

      if project do
        {:ok, assign(socket, :project, project)}
      else
        {:error, %{reason: "project_not_found"}}
      end
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("event", payload, socket) do
    project = socket.assigns.project

    sequence = payload["sequence"] || 0
    event_type = payload["event_type"] || "unknown"
    content = payload["content"] || ""
    metadata = payload["metadata"] || "{}"

    Ingestion.record_setup_event(
      project.id,
      sequence,
      event_type,
      content,
      metadata
    )

    Projects.broadcast_setup_event(project, %{
      sequence: sequence,
      event_type: event_type,
      content: content,
      metadata: metadata
    })

    {:reply, :ok, socket}
  end
end
