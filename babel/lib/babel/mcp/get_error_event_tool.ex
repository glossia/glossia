defmodule Babel.MCP.GetErrorEventTool do
  @moduledoc "Fetch a single captured event by issue + event id, scoped to an organization."

  use Hermes.Server.Component, type: :tool, annotations: %{"readOnlyHint" => true}

  alias Babel.Errors
  alias Babel.MCP.Authorization
  alias Hermes.MCP.Error
  alias Hermes.Server.Response

  schema do
    field :organization_id, :integer,
      required: true,
      description: "Organization that owns the issue."

    field :issue_id, :string,
      required: true,
      description: "Issue identifier (UUID)."

    field :event_id, :string,
      required: true,
      description: "Event identifier, canonical UUID or 32-char hex form."
  end

  @impl true
  def execute(%{organization_id: org_id, issue_id: issue_id, event_id: event_id}, frame) do
    case Authorization.authorize(frame) do
      :ok ->
        case Errors.get_event(org_id, issue_id, event_id) do
          {:ok, event} ->
            response =
              Response.tool()
              |> Response.structured(%{event: serialize(event)})

            {:reply, response, frame}

          {:error, :not_found} ->
            {:error, Error.execution("Event not found"), frame}
        end

      {:error, error} ->
        {:error, error, frame}
    end
  end

  defp serialize(event) do
    %{
      event_id: to_string(event.event_id),
      timestamp: format_timestamp(event.timestamp),
      level: to_string(event.level),
      environment: value_or_nil(event.environment),
      release: value_or_nil(event.release),
      exception_type: value_or_nil(event.exception_type),
      exception_value: value_or_nil(event.exception_value),
      top_frame_function: value_or_nil(event.top_frame_function),
      top_frame_filename: value_or_nil(event.top_frame_filename),
      tags: event.tags,
      payload: event.payload
    }
  end

  defp format_timestamp(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp format_timestamp(nil), do: nil

  defp value_or_nil(nil), do: nil
  defp value_or_nil(""), do: nil
  defp value_or_nil(value), do: to_string(value)
end
