defmodule Babel.MCP.ListOrganizationsTool do
  @moduledoc "List organizations and their current relationship state."

  use Hermes.Server.Component, type: :tool, annotations: %{"readOnlyHint" => true}

  alias Babel.Organizations
  alias Babel.Organizations.Organization
  alias Babel.MCP.Authorization
  alias Babel.MCP.OrganizationSerializer
  alias Hermes.Server.Response

  @states Organization.states()
  @sort_columns ["name", "state", "notes"]

  schema do
    field :state, :string, enum: @states, description: "Optional engagement state to filter by."

    field :search, :string,
      description: "Optional search across organization names, translation tools, and notes."

    field :sort_by, :string, enum: @sort_columns, description: "Column used to sort the results."

    field :sort_order, :string,
      enum: ["asc", "desc"],
      description: "Direction used to sort the results."
  end

  @impl true
  def execute(params, frame) do
    case Authorization.authorize(frame) do
      :ok ->
        options =
          [
            state: params[:state],
            search: params[:search],
            sort_by: params[:sort_by],
            sort_order: params[:sort_order]
          ]
          |> Enum.reject(fn {_key, value} -> is_nil(value) end)

        response =
          Response.tool()
          |> Response.structured(%{
            organizations:
              options
              |> Organizations.list_organizations()
              |> Enum.map(&OrganizationSerializer.serialize/1),
            summary: Organizations.summary()
          })

        {:reply, response, frame}

      {:error, error} ->
        {:error, error, frame}
    end
  end
end
