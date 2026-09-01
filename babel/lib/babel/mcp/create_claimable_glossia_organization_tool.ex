defmodule Babel.MCP.CreateClaimableGlossiaOrganizationTool do
  @moduledoc "Create a public, claimable Glossia organization for a Babel organization."

  use Hermes.Server.Component, type: :tool

  alias Babel.MCP.Authorization
  alias Babel.MCP.OrganizationSerializer
  alias Babel.Organizations
  alias Hermes.MCP.Error
  alias Hermes.Server.Response

  schema do
    field :organization_id, :integer,
      required: true,
      description: "Babel organization identifier."

    field :handle, :string,
      required: true,
      description: "Glossia handle. It becomes the public organization address."
  end

  @impl true
  def execute(%{organization_id: organization_id, handle: handle}, frame) do
    case Authorization.authorize_write(frame) do
      :ok -> create_claimable_organization(organization_id, handle, frame)
      {:error, error} -> {:error, error, frame}
    end
  end

  defp create_claimable_organization(organization_id, handle, frame) do
    case Organizations.get_organization(organization_id) do
      nil ->
        {:error, Error.execution("Organization not found"), frame}

      organization ->
        case Organizations.create_claimable_glossia_organization(
               organization,
               frame.assigns.current_account,
               handle
             ) do
          {:ok, updated_organization} ->
            response =
              Response.tool()
              |> Response.structured(%{
                organization: OrganizationSerializer.serialize(updated_organization)
              })

            {:reply, response, frame}

          {:error, :already_connected} ->
            {:error, Error.execution("This organization is already connected to Glossia"), frame}

          {:error, :unauthorized} ->
            {:error, Error.execution("Pomerium authentication is required"), frame}

          {:error, reason} ->
            {:error,
             Error.execution("Could not create the claimable organization: #{inspect(reason)}"),
             frame}
        end
    end
  end
end
