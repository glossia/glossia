defmodule Babel.MCP.GetOperationsOverviewTool do
  @moduledoc "Return current operations totals and the work items that make up the queue."

  use Hermes.Server.Component, type: :tool, annotations: %{"readOnlyHint" => true}

  alias Babel.MCP.Authorization
  alias Babel.MCP.WorkItemSerializer
  alias Babel.Operations
  alias Hermes.Server.Response

  schema do
  end

  @impl true
  def execute(_params, frame) do
    case Authorization.authorize(frame) do
      :ok ->
        dashboard = Operations.dashboard()

        response =
          Response.tool()
          |> Response.structured(%{
            open_count: dashboard.open_count,
            blocked_count: dashboard.blocked_count,
            due_this_week_count: dashboard.due_this_week_count,
            completed_count: dashboard.completed_count,
            work_items: Enum.map(dashboard.work_items, &WorkItemSerializer.serialize/1)
          })

        {:reply, response, frame}

      {:error, error} ->
        {:error, error, frame}
    end
  end
end
