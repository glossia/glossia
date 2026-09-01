defmodule Babel.MCP.TransferClaimableGlossiaOrganizationTool do
  @moduledoc "Transfer a claimable Glossia organization to an existing Glossia user."

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

    field :email, :string,
      required: true,
      description: "Email address of an existing Glossia user who will own the organization."
  end

  @impl true
  def execute(%{organization_id: organization_id, email: email}, frame) do
    case Authorization.authorize_write(frame) do
      :ok -> transfer_organization(organization_id, email, frame)
      {:error, error} -> {:error, error, frame}
    end
  end

  defp transfer_organization(organization_id, email, frame) do
    case Organizations.get_organization(organization_id) do
      nil ->
        {:error, Error.execution("Organization not found"), frame}

      organization ->
        organization
        |> Organizations.transfer_claimable_glossia_organization(
          frame.assigns.current_account,
          email
        )
        |> transfer_response(email, frame)
    end
  end

  defp transfer_response({:ok, updated_organization}, email, frame) do
    response =
      Response.tool()
      |> Response.structured(%{
        organization: OrganizationSerializer.serialize(updated_organization),
        transferred_to: email
      })

    {:reply, response, frame}
  end

  defp transfer_response({:error, :not_connected}, _email, frame),
    do: {:error, Error.execution("Connect this organization to Glossia first"), frame}

  defp transfer_response({:error, :not_claimable}, _email, frame),
    do: {:error, Error.execution("This organization is no longer claimable"), frame}

  defp transfer_response({:error, :unauthorized}, _email, frame),
    do: {:error, Error.execution("Pomerium authentication is required"), frame}

  defp transfer_response({:error, "organization_not_claimable"}, _email, frame),
    do: {:error, Error.execution("This organization is no longer claimable"), frame}

  defp transfer_response({:error, "organization_or_user_not_found"}, _email, frame),
    do: {:error, Error.execution("The organization or recipient was not found in Glossia"), frame}

  defp transfer_response({:error, reason}, _email, frame),
    do:
      {:error, Error.execution("Could not transfer the organization: #{inspect(reason)}"), frame}
end
