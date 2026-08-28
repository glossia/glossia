defmodule Babel.MCP.ListWorkItemsTool do
  @moduledoc "List operational work items, optionally limited to an operations area."

  use Hermes.Server.Component, type: :tool, annotations: %{"readOnlyHint" => true}

  alias Babel.MCP.Authorization
  alias Babel.MCP.WorkItemSerializer
  alias Babel.Operations
  alias Hermes.Server.Response

  @areas ["Customer success", "Finance", "Growth", "Operations"]

  schema do
    field :area, :string,
      enum: @areas,
      description: "Optional operations area to filter by."
  end

  @impl true
  def execute(params, frame) do
    case Authorization.authorize(frame) do
      :ok ->
        work_items =
          case params do
            %{area: area} -> Operations.list_work_items(area)
            _ -> Operations.list_work_items()
          end

        response =
          Response.tool()
          |> Response.structured(%{
            work_items: Enum.map(work_items, &WorkItemSerializer.serialize/1)
          })

        {:reply, response, frame}

      {:error, error} ->
        {:error, error, frame}
    end
  end
end
