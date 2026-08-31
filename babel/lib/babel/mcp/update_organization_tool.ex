defmodule Babel.MCP.UpdateOrganizationTool do
  @moduledoc "Update an organization's details and relationship state."

  use Hermes.Server.Component, type: :tool

  alias Babel.MCP.Authorization
  alias Babel.MCP.OrganizationSerializer
  alias Babel.Organizations
  alias Babel.Organizations.Organization
  alias Hermes.MCP.Error
  alias Hermes.Server.Response

  @states Organization.states()

  schema do
    field :id, :integer, required: true, description: "Organization identifier."
    field :name, :string, description: "Company name."
    field :website_url, :string, description: "Company secure website address."

    field :origin_url, :string,
      description: "Public secure web address that led to this organization."

    field :state, :string, enum: @states, description: "Engagement state."

    field :translation_tool, :string,
      description: "Known translation tool, if publicly evidenced."

    field :glossia_organization_id, :string,
      description: "Optional Glossia organization identifier for usage data."

    field :notes, :string, description: "Internal research notes."
  end

  @impl true
  def execute(%{id: id} = params, frame) do
    case Authorization.authorize_write(frame) do
      :ok -> update_organization(id, Map.delete(params, :id), frame)
      {:error, error} -> {:error, error, frame}
    end
  end

  defp update_organization(id, attributes, frame) do
    case Organizations.get_organization(id) do
      nil ->
        {:error, Error.execution("Organization not found"), frame}

      organization ->
        case Organizations.update_organization(organization, attributes) do
          {:ok, updated_organization} ->
            response =
              Response.tool()
              |> Response.structured(%{
                organization: OrganizationSerializer.serialize(updated_organization)
              })

            {:reply, response, frame}

          {:error, changeset} ->
            {:error,
             Error.execution("Could not update organization: #{format_errors(changeset)}"), frame}
        end
    end
  end

  defp format_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, _options} -> message end)
    |> inspect()
  end
end
