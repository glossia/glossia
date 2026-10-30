defmodule GlossiaEnterpriseWeb.AuthenticationSettingsLive do
  use GlossiaWeb, :live_view
  use Gettext, backend: GlossiaEnterpriseWeb.Gettext
  import GlossiaWeb.DashboardComponents, only: [page_header: 1]
  import Noora.Card
  alias GlossiaEnterprise.OrganizationAuthentication, as: Authentication
  alias GlossiaEnterprise.SCIM
  alias Glossia.Organizations

  def mount(_params, _session, socket) do
    organization = Organizations.get_organization_for_account(socket.assigns.account)

    unless Glossia.Roles.has_organization_role?(
             socket.assigns.current_user,
             organization,
             "admin"
           ),
           do: raise(Ecto.NoResultsError, queryable: Glossia.Accounts.Organization)

    {:ok,
     socket
     |> assign(:page_title, gettext("Authentication"))
     |> assign(:scim_plaintext, nil)
     |> assign(:scim_form, to_form(%{"name" => ""}, as: :scim))
     |> assign(:breadcrumb_items, [
       {gettext("Authentication"), ~p"/#{socket.assigns.handle}/-/settings/authentication"}
     ])
     |> load(organization)}
  end

  defp load(socket, organization) do
    params =
      Map.new(~w(auth_provider auth_domain auth_issuer auth_client_id), fn field ->
        {field, Map.get(organization, String.to_existing_atom(field)) || ""}
      end)
      |> Map.put("auth_client_secret", "")
      |> Map.merge(
        Map.new(
          Authentication.settings(organization)
          |> Map.take([:auth_authorize_url, :auth_token_url, :auth_userinfo_url]),
          fn {key, value} -> {Atom.to_string(key), value || ""} end
        )
      )

    params =
      Map.update!(params, "auth_provider", fn provider ->
        if provider == "", do: "disabled", else: provider
      end)

    socket
    |> assign(:organization, organization)
    |> assign(:sso_enforced, Authentication.enforced?(organization))
    |> assign(:mfa_enforced, Authentication.mfa_enforced?(organization))
    |> assign(:scim_tokens, SCIM.list_tokens(organization, socket.assigns.current_user))
    |> assign(:provider, params["auth_provider"])
    |> assign(:form, to_form(params, as: :authentication))
  end

  def handle_event("provider", %{"value" => [value]}, socket),
    do: handle_event("provider", %{"value" => value}, socket)

  def handle_event("provider", %{"value" => value}, socket)
      when value in ["disabled", "google", "okta", "oauth2"] do
    params = Map.put(socket.assigns.form.params, "auth_provider", value)

    {:noreply,
     socket |> assign(:provider, value) |> assign(:form, to_form(params, as: :authentication))}
  end

  def handle_event("validate", %{"authentication" => params}, socket) do
    # The provider event owns the selection; the select's native change can
    # arrive with the previous hidden field value while that event is in flight.
    params = Map.put(params, "auth_provider", socket.assigns.provider)
    {:noreply, assign(socket, :form, to_form(params, as: :authentication))}
  end

  def handle_event("save", %{"authentication" => params}, socket) do
    params =
      Map.update(params, "auth_provider", "", fn provider ->
        if provider == "disabled", do: "", else: provider
      end)

    case Authentication.save(socket.assigns.organization, socket.assigns.current_user, params) do
      {:ok, organization} ->
        {:noreply,
         socket
         |> load(organization)
         |> put_flash(:info, gettext("Authentication settings saved."))}

      {:error, %Ecto.Changeset{} = changeset} ->
        # Both organization and endpoint validation share this form. Never render
        # stored or submitted secrets back into a failed form.
        params =
          Map.merge(socket.assigns.form.params, params) |> Map.put("auth_client_secret", "")

        {:noreply,
         assign(socket, :form, to_form(params, as: :authentication, errors: changeset.errors))}

      {:error, :enforcement_enabled} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           gettext("Disable SSO enforcement before changing the identity provider.")
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not save authentication settings."))}
    end
  end

  def handle_event("verify", _, socket) do
    case Authentication.verify(socket.assigns.organization, socket.assigns.current_user) do
      {:ok, organization} ->
        {:noreply,
         socket |> load(organization) |> put_flash(:info, gettext("Domain ownership verified."))}

      {:error, _} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           gettext(
             "Verification record was not found. Check the name and value, then try again after the record has propagated."
           )
         )}
    end
  end

  def handle_event("enforcement", _, socket) do
    case Authentication.set_enforcement(
           socket.assigns.organization,
           socket.assigns.current_user,
           not socket.assigns.sso_enforced,
           socket.assigns.organization_sso
         ) do
      {:ok, enabled} ->
        {:noreply,
         socket
         |> assign(:sso_enforced, enabled)
         |> put_flash(:info, gettext("SSO enforcement updated."))}

      {:error, _} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           gettext(
             "Verify the domain and sign in with this organization's provider before enforcing SSO."
           )
         )}
    end
  end

  def handle_event("create-scim-token", %{"scim" => attrs}, socket) do
    case SCIM.create_token(socket.assigns.organization, socket.assigns.current_user, attrs) do
      {:ok, %{plaintext: plaintext}} ->
        {:noreply,
         socket
         |> assign(
           :scim_tokens,
           SCIM.list_tokens(socket.assigns.organization, socket.assigns.current_user)
         )
         |> assign(:scim_plaintext, plaintext)
         |> assign(:scim_form, to_form(%{"name" => ""}, as: :scim))}

      {:error, _} ->
        {:noreply,
         put_flash(socket, :error, gettext("Enter a token name of at most 100 characters."))}
    end
  end

  def handle_event("mfa-enforcement", _, socket) do
    case Authentication.set_mfa_enforcement(
           socket.assigns.organization,
           socket.assigns.current_user,
           not socket.assigns.mfa_enforced,
           socket.assigns.browser_token
         ) do
      {:ok, enabled} ->
        {:noreply,
         socket
         |> assign(:mfa_enforced, enabled)
         |> put_flash(:info, gettext("MFA enforcement updated."))}

      {:error, _} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           gettext(
             "Enable your own two-factor authentication and sign in again before changing this policy."
           )
         )}
    end
  end

  def handle_event("dismiss-scim-token", _, socket),
    do: {:noreply, assign(socket, :scim_plaintext, nil)}

  def handle_event("revoke-scim-token", %{"id" => id}, socket) do
    case SCIM.revoke_token(socket.assigns.organization, socket.assigns.current_user, id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(
           :scim_tokens,
           SCIM.list_tokens(socket.assigns.organization, socket.assigns.current_user)
         )
         |> assign(:scim_plaintext, nil)
         |> put_flash(:info, gettext("SCIM token revoked."))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not revoke the SCIM token."))}
    end
  end

  defp read_only_attributes, do: %{readonly: true}

  def render(assigns) do
    ~H"""
    <div id="authentication-settings">
      <.page_header
        title={gettext("Authentication")}
        description={
          gettext("Let your team sign in with Google Workspace, Okta, or a custom OAuth2 provider.")
        }
      />
      <.card title={gettext("Organization sign-in")} icon="lock_password">
        <.card_section>
          <.form
            for={@form}
            id="organization-authentication-form"
            phx-submit="save"
            phx-change="validate"
            data-part="form"
          >
            <input type="hidden" name="authentication[auth_provider]" value={@provider} />
            <Noora.Select.select
              id={"authentication-provider-#{@provider}"}
              value={@provider}
              name="authentication_provider_selection"
              label={gettext("Identity provider")}
              on_value_change="provider"
            >
              <:item value="disabled" label={gettext("Disabled")} />
              <:item value="google" label="Google Workspace" />
              <:item value="okta" label="Okta" />
              <:item value="oauth2" label={gettext("Custom OAuth2")} />
            </Noora.Select.select>
            <Noora.TextInput.text_input
              :if={@provider != "disabled"}
              field={@form[:auth_domain]}
              aria-label={gettext("Work email domain")}
              label={gettext("Work email domain")}
              placeholder="example.com"
              required
            />
            <p :if={@provider == "google"}>
              {gettext(
                "Team members must belong to this Google Workspace domain. Personal Google accounts do not qualify."
              )}
            </p>
            <Noora.TextInput.text_input
              :if={@provider == "okta"}
              field={@form[:auth_issuer]}
              aria-label={gettext("Okta issuer")}
              label={gettext("Okta issuer")}
              placeholder="https://example.okta.com"
              required
            />
            <Noora.TextInput.text_input
              :if={@provider == "oauth2"}
              field={@form[:auth_issuer]}
              aria-label={gettext("Provider base URL")}
              label={gettext("Provider base URL")}
              placeholder="https://identity.example.com"
              required
            />
            <Noora.TextInput.text_input
              :if={@provider == "oauth2"}
              field={@form[:auth_authorize_url]}
              aria-label={gettext("Authorization URL")}
              label={gettext("Authorization URL")}
              placeholder="https://identity.example.com/authorize"
              required
            />
            <Noora.TextInput.text_input
              :if={@provider == "oauth2"}
              field={@form[:auth_token_url]}
              aria-label={gettext("Token URL")}
              label={gettext("Token URL")}
              placeholder="https://identity.example.com/token"
              required
            />
            <Noora.TextInput.text_input
              :if={@provider == "oauth2"}
              field={@form[:auth_userinfo_url]}
              aria-label={gettext("User information URL")}
              label={gettext("User information URL")}
              placeholder="https://identity.example.com/userinfo"
              required
            />
            <p :if={@provider == "oauth2"}>
              {gettext(
                "Use HTTPS endpoints on the public internet. The provider must support authorization code with PKCE and return sub, email, and email_verified: true from user information."
              )}
            </p>
            <Noora.TextInput.text_input
              :if={@provider in ["okta", "oauth2"]}
              field={@form[:auth_client_id]}
              aria-label={gettext("Client identifier")}
              label={gettext("Client identifier")}
              required
            />
            <Noora.TextInput.text_input
              :if={@provider in ["okta", "oauth2"]}
              field={@form[:auth_client_secret]}
              input_type="password"
              aria-label={gettext("Client secret")}
              label={gettext("Client secret")}
              placeholder={
                if @organization.auth_client_secret,
                  do: gettext("Leave blank to keep the saved secret"),
                  else: gettext("Enter your client secret")
              }
            />
            <Noora.TextInput.text_input
              :if={@provider in ["okta", "oauth2"]}
              name="callback"
              value={Authentication.callback_url()}
              aria-label={gettext("Redirect address")}
              label={gettext("Redirect address")}
              {read_only_attributes()}
            />
            <p>
              {gettext(
                "New team members receive basic read access. Administrators can grant more permissions from Members."
              )}
            </p>
            <Noora.Button.button label={gettext("Save authentication settings")} />
          </.form>
        </.card_section>
        <.card_section :if={@provider == "google"}>
          <Noora.Alert.alert
            id="google-workspace-setup"
            type="secondary"
            status="information"
            size="large"
            title={gettext("Set up Google Workspace sign-in")}
          >
            <p>
              {gettext(
                "Glossia manages the Google connection. You do not need to create an application in Google Cloud or register a redirect address."
              )}
            </p>
            <ol>
              <li>
                {gettext("Enter your work email domain and save the authentication settings.")}
              </li>
              <li>
                {gettext(
                  "At your DNS provider, add the TXT record shown under Verify domain ownership, then select Verify domain."
                )}
              </li>
              <li>
                {gettext(
                  "Team members can then enter their work email on the login page and select Continue with your organization, or use Log in with Google."
                )}
              </li>
            </ol>
            <p>
              {gettext(
                "If Google blocks sign-in because your organization restricts third-party apps, ask a Google Workspace administrator to open Google Admin console → Security → Access and data control → API controls → Manage third-party app access, find Glossia, and allow the requested sign-in permissions according to your organization's policy."
              )}
            </p>
            <:action>
              <Noora.Button.button
                href={locale_path(~p"/docs/how-to/organization-sign-in")}
                label={gettext("Read the organization sign-in guide")}
                variant="secondary"
                size="small"
              />
            </:action>
          </Noora.Alert.alert>
        </.card_section>
      </.card>
      <.card title={gettext("Require single sign-on")} icon="lock_password">
        <.card_section data-part="form">
          <p>
            {gettext(
              "Require organization sign-in for signed-in browser access to this account, including existing sessions. API tokens and anonymous public pages are unchanged."
            )}
          </p>
          <Noora.Badge.badge
            label={if @sso_enforced, do: gettext("Enforced"), else: gettext("Optional")}
            color={if @sso_enforced, do: "success", else: "neutral"}
          />
          <p>
            {gettext(
              "Verify your domain and test organization sign-in with your administrator account before enabling enforcement. Disable enforcement before changing providers."
            )}
          </p>
          <Noora.Button.button
            id="sso-enforcement"
            type="button"
            phx-click="enforcement"
            label={if @sso_enforced, do: gettext("Disable enforcement"), else: gettext("Enforce SSO")}
            variant="secondary"
          />
        </.card_section>
      </.card>
      <.card title={gettext("Require two-factor authentication")} icon="lock_password">
        <.card_section data-part="form">
          <p>
            {gettext(
              "Require members to enroll an authenticator before accessing this organization in a browser. Existing sessions are checked too. Members keep access to personal security settings so they can enroll."
            )}
          </p>
          <Noora.Badge.badge
            label={if @mfa_enforced, do: gettext("Enforced"), else: gettext("Optional")}
            color={if @mfa_enforced, do: "success", else: "neutral"}
          />
          <p>
            {gettext(
              "This policy requires Glossia MFA even when your identity provider also requires MFA. API tokens and anonymous public pages are unchanged."
            )}
          </p>
          <Noora.Button.button
            id="mfa-enforcement"
            type="button"
            phx-click="mfa-enforcement"
            label={
              if @mfa_enforced, do: gettext("Disable MFA enforcement"), else: gettext("Enforce MFA")
            }
            variant="secondary"
          />
          <Noora.Button.button
            href={~p"/-/settings/security"}
            label={gettext("Manage your two-factor authentication")}
            variant="secondary"
          />
        </.card_section>
      </.card>
      <.card title={gettext("SCIM provisioning")} icon="users">
        <.card_section data-part="form">
          <p>
            {gettext(
              "Let your identity provider create members, manage organization roles, and revoke access. SCIM does not replace single sign-on."
            )}
          </p>
          <Noora.TextInput.text_input
            name="scim_endpoint"
            value={url(~p"/scim/v2")}
            label={gettext("SCIM endpoint URL")}
            {read_only_attributes()}
          />
          <.form for={@scim_form} id="scim-token-form" phx-submit="create-scim-token" data-part="form">
            <Noora.TextInput.text_input
              field={@scim_form[:name]}
              label={gettext("Token name")}
              placeholder="Okta"
              required
            />
            <Noora.Button.button label={gettext("Generate SCIM token")} variant="secondary" />
          </.form>
          <Noora.Button.button
            href={locale_path(~p"/docs/how-to/scim-provisioning")}
            label={gettext("Read the SCIM provisioning guide")}
            variant="secondary"
          />
        </.card_section>
        <.card_section :if={@scim_plaintext} data-part="form" id="scim-token-secret">
          <Noora.Alert.alert
            id="scim-token-warning"
            type="secondary"
            status="warning"
            size="large"
            title={gettext("Copy this token now")}
          >
            {gettext(
              "This token is shown only once. Store it securely and enter it in your identity provider as a bearer token."
            )}
          </Noora.Alert.alert>
          <Noora.TextInput.text_input
            name="scim_token"
            value={@scim_plaintext}
            label={gettext("SCIM bearer token")}
            {read_only_attributes()}
          />
          <Noora.Button.button
            type="button"
            phx-click="dismiss-scim-token"
            label={gettext("I have copied the token")}
            variant="secondary"
          />
        </.card_section>
        <.card_section :for={token <- @scim_tokens} data-part="form" id={"scim-token-#{token.id}"}>
          <Noora.TextInput.text_input
            name={"scim_token_name_#{token.id}"}
            value={token.name}
            label={gettext("Provisioning token")}
            {read_only_attributes()}
          />
          <Noora.Button.button
            type="button"
            phx-click="revoke-scim-token"
            phx-value-id={token.id}
            label={gettext("Revoke token")}
            variant="destructive"
            data-confirm={
              gettext("Revoke this token? Provisioning with this token will stop immediately.")
            }
          />
        </.card_section>
        <.card_section :if={@scim_tokens == []} class="noora-table" data-part="empty-tokens">
          <Noora.Table.table_empty_state
            icon="lock_password"
            title={gettext("No provisioning tokens")}
            subtitle={
              gettext(
                "Generate a token to connect your identity provider. Existing members are unchanged."
              )
            }
          />
        </.card_section>
      </.card>
      <.card
        :if={@organization.auth_domain_token}
        title={gettext("Verify domain ownership")}
        icon="world"
      >
        <.card_section data-part="verification">
          <Noora.Badge.badge
            label={
              if Authentication.verified?(@organization),
                do: gettext("Verified"),
                else: gettext("Awaiting verification")
            }
            color={if Authentication.verified?(@organization), do: "success", else: "warning"}
          />
          <p>
            {gettext(
              "Add a DNS TXT record with your domain provider using the name and value below. Organization sign-in stays unavailable until ownership is verified. Keep this record in place. Ownership is checked daily and expires 30 days after the last successful check."
            )}
          </p>
          <Noora.TextInput.text_input
            name="record_name"
            value={Authentication.record_name(@organization)}
            aria-label={gettext("Record name")}
            label={gettext("Record name")}
            {read_only_attributes()}
          />
          <Noora.TextInput.text_input
            name="record_value"
            value={Authentication.record_value(@organization)}
            aria-label={gettext("Record value")}
            label={gettext("Record value")}
            {read_only_attributes()}
          />
          <Noora.Button.button
            type="button"
            phx-click="verify"
            label={gettext("Verify domain")}
            variant="secondary"
          />
        </.card_section>
      </.card>
    </div>
    """
  end
end
