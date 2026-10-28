defmodule GlossiaEnterprise.MCP.VerifyOrganizationAuthenticationTool do
  @moduledoc "Verify the organization SSO domain against its DNS TXT record. Requires organization:admin."
  use Hermes.Server.Component, type: :tool
  alias Glossia.MCP.Authorization, as: Auth
  alias Glossia.Organizations
  alias GlossiaEnterprise.OrganizationAuthentication, as: Authentication
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Organization handle."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, user, account} <- Auth.fetch_organization_context(frame, params["handle"]),
         :ok <- Auth.authorize(frame, :organization_admin, user, account),
         organization when not is_nil(organization) <-
           Organizations.get_organization_for_account(account) do
      case Authentication.verify(organization, user) do
        {:ok, verified} ->
          {:ok, configuration} = Authentication.configuration(verified, user)
          {:reply, Response.tool() |> Response.text(JSON.encode!(configuration)), frame}

        {:error, reason} ->
          {:error, Hermes.MCP.Error.execution("Domain verification failed: #{reason}"), frame}
      end
    else
      nil -> {:error, Hermes.MCP.Error.execution("Organization not found"), frame}
      {:error, error} -> {:error, error, frame}
    end
  end
end
