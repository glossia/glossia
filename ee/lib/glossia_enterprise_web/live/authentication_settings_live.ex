defmodule GlossiaEnterpriseWeb.AuthenticationSettingsLive do
  use GlossiaWeb, :live_view
  use Gettext, backend: GlossiaEnterpriseWeb.Gettext
  import GlossiaWeb.DashboardComponents, only: [page_header: 1]
  import Noora.Card
  alias GlossiaEnterprise.OrganizationAuthentication, as: Authentication
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

    params =
      Map.update!(params, "auth_provider", fn provider ->
        if provider == "", do: "disabled", else: provider
      end)

    socket
    |> assign(:organization, organization)
    |> assign(:provider, params["auth_provider"])
    |> assign(:form, to_form(params, as: :authentication))
  end

  def handle_event("provider", %{"value" => [value]}, socket),
    do: handle_event("provider", %{"value" => value}, socket)

  def handle_event("provider", %{"value" => value}, socket)
      when value in ["disabled", "google", "okta"] do
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
        changeset = Ecto.Changeset.delete_change(changeset, :auth_client_secret)

        changeset = %{
          changeset
          | action: :update,
            data: %{changeset.data | auth_client_secret: nil}
        }

        {:noreply, assign(socket, :form, to_form(changeset, as: :authentication))}

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

  defp read_only_attributes, do: %{readonly: true}

  def render(assigns) do
    ~H"""
    <div id="authentication-settings">
      <.page_header
        title={gettext("Authentication")}
        description={gettext("Let your team sign in with Google Workspace or Okta.")}
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
              :if={@provider == "okta"}
              field={@form[:auth_client_id]}
              aria-label={gettext("Client identifier")}
              label={gettext("Client identifier")}
              required
            />
            <Noora.TextInput.text_input
              :if={@provider == "okta"}
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
              :if={@provider == "okta"}
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
