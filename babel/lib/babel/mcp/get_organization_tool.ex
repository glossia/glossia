defmodule Babel.MCP.GetOrganizationTool do
  @moduledoc "Return one organization with its chronological interaction history."

  use Hermes.Server.Component, type: :tool, annotations: %{"readOnlyHint" => true}

  alias Babel.Organizations
  alias Babel.MCP.Authorization
  alias Babel.MCP.OrganizationSerializer
  alias Hermes.MCP.Error
  alias Hermes.Server.Response

  schema do
    field :id, :integer, required: true, description: "Organization identifier."
  end

  @impl true
  def execute(%{id: id}, frame) do
    case Authorization.authorize(frame) do
      :ok ->
        case Organizations.get_organization(id) do
          nil ->
            {:error, Error.execution("Organization not found"), frame}

          organization ->
            response =
              Response.tool()
              |> Response.structured(%{
                organization: OrganizationSerializer.serialize_with_interactions(organization)
              })

            {:reply, response, frame}
        end

      {:error, error} ->
        {:error, error, frame}
    end
  end
end
