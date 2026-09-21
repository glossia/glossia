defmodule Babel.MCP.ListErrorEventsTool do
  @moduledoc "List captured events for an issue, newest first, scoped to an organization."

  use Hermes.Server.Component, type: :tool, annotations: %{"readOnlyHint" => true}

  alias Babel.Errors
  alias Babel.MCP.Authorization
  alias Hermes.Server.Response

  schema do
    field :organization_id, :integer,
      required: true,
      description: "Organization that owns the issue."

    field :issue_id, :string,
      required: true,
      description: "Issue identifier (UUID)."

    field :from, :string, description: "Inclusive ISO 8601 lower bound on the event timestamp."

    field :to, :string, description: "Inclusive ISO 8601 upper bound on the event timestamp."

    field :limit, :integer, description: "Maximum number of events to return, 1-200 (default 25)."
  end

  @impl true
  def execute(%{organization_id: org_id, issue_id: issue_id} = params, frame) do
    case Authorization.authorize(frame) do
      :ok ->
        events =
          Errors.list_events_for_issue(org_id, issue_id, event_opts(params))
          |> Enum.map(&serialize/1)

        response =
          Response.tool()
          |> Response.structured(%{events: events})

        {:reply, response, frame}

      {:error, error} ->
        {:error, error, frame}
    end
  end

  defp event_opts(params) do
    [
      limit: clamp_limit(params[:limit]),
      from: parse_datetime(params[:from]),
      to: parse_datetime(params[:to])
    ]
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  end

  defp clamp_limit(n) when is_integer(n) and n > 0, do: min(n, 200)
  defp clamp_limit(_), do: nil

  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
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
      top_frame_filename: value_or_nil(event.top_frame_filename)
    }
  end

  defp format_timestamp(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp format_timestamp(nil), do: nil

  defp value_or_nil(nil), do: nil
  defp value_or_nil(""), do: nil
  defp value_or_nil(value), do: to_string(value)
end
