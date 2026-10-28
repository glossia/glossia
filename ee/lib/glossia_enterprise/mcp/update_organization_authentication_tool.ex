defmodule GlossiaEnterprise.MCP.UpdateOrganizationAuthenticationTool do
  @moduledoc "Configure organization SSO. Requires organization:admin. Enabling enforcement requires a tested browser SSO session in Authentication settings; this tool can disable it for recovery."
  use Hermes.Server.Component, type: :tool
  alias Glossia.{ChangesetErrors, Organizations}
  alias Glossia.MCP.Authorization, as: Auth
  alias GlossiaEnterprise.OrganizationAuthentication, as: Authentication
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Organization handle."

    field :auth_provider, :string,
      description: "google, okta, oauth2, or an empty string to disable."

    field :auth_domain, :string, description: "Work email domain to verify with DNS."
    field :auth_issuer, :string, description: "Okta issuer or custom OAuth2 HTTPS base URL."
    field :auth_client_id, :string, description: "OAuth2 client identifier."

    field :auth_client_secret, :string,
      description: "OAuth2 client secret. Omit or leave blank to preserve the saved value."

    field :auth_authorize_url, :string, description: "Custom OAuth2 HTTPS authorization endpoint."
    field :auth_token_url, :string, description: "Custom OAuth2 HTTPS token endpoint."

    field :auth_userinfo_url, :string,
      description: "Custom OAuth2 HTTPS user information endpoint."

    field :sso_enforced, :boolean,
      description:
        "Set false to disable enforcement before editing a provider or to recover access. Cannot enable enforcement here."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, user, account} <- Auth.fetch_organization_context(frame, params["handle"]),
         :ok <- Auth.authorize(frame, :organization_admin, user, account),
         organization when not is_nil(organization) <-
           Organizations.get_organization_for_account(account) do
      case Authentication.configure(organization, user, params) do
        {:ok, configuration} ->
          {:reply, Response.tool() |> Response.text(JSON.encode!(configuration)), frame}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:error, Hermes.MCP.Error.execution(ChangesetErrors.to_inline_string(changeset)), frame}

        {:error, reason} ->
          {:error, Hermes.MCP.Error.execution("Authentication update failed: #{reason}"), frame}
      end
    else
      nil -> {:error, Hermes.MCP.Error.execution("Organization not found"), frame}
      {:error, error} -> {:error, error, frame}
    end
  end
end
