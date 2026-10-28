defmodule GlossiaEnterpriseWeb.OrganizationAuthController do
  use GlossiaWeb, :controller
  use Gettext, backend: GlossiaEnterpriseWeb.Gettext
  alias GlossiaEnterprise.OrganizationAuthentication, as: Authentication
  alias Glossia.Organizations

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "organization_login",
    scale: :timer.minutes(1),
    limit: 20,
    by: :ip,
    format: :text

  def request(conn, params) do
    conn = delete_session(conn, :organization_auth)
    email = get_in(params, ["organization", "email"])

    with organization when not is_nil(organization) <- Authentication.for_email(email),
         {:ok, config} <- Authentication.config(organization),
         {:ok, %{url: url, session_params: session_params}} <-
           config[:strategy].authorize_url(config) do
      conn
      |> delete_session(:oauth_session_params)
      |> put_session(:organization_auth, %{
        organization_id: organization.id,
        fingerprint: Authentication.provider_fingerprint(organization),
        session_params: session_params,
        link_user_id: conn.assigns[:current_user] && conn.assigns.current_user.id,
        started_at: System.system_time(:second)
      })
      |> redirect(external: url)
    else
      _ -> failed(conn)
    end
  end

  def callback(conn, params) do
    state = get_session(conn, :organization_auth)
    conn = delete_session(conn, :organization_auth)

    with %{
           organization_id: id,
           fingerprint: saved,
           session_params: session_params,
           started_at: started_at
         } <- state,
         true <- (System.system_time(:second) - started_at) in 0..600,
         organization when not is_nil(organization) <- Organizations.get_organization(id),
         true <-
           Authentication.provider_fingerprint(organization) == saved and
             not is_nil(organization.auth_domain_verified_at),
         {:ok, config} <- Authentication.config(organization),
         {:ok, response} <-
           config[:strategy].callback(
             Keyword.put(config, :session_params, session_params),
             params
           ),
         {:ok, user} <-
           Authentication.sign_in(organization, response,
             link_user_id: state[:link_user_id],
             fingerprint: saved
           ) do
      Glossia.Events.emit("user.signed_in", user.account, user,
        resource_type: "user",
        resource_id: to_string(user.id),
        summary: "Signed in with organization identity provider"
      )

      conn
      |> put_session(:user_id, user.id)
      |> put_session(:organization_sso, Authentication.session_proof(organization, user))
      |> delete_session(:oauth_session_params)
      |> delete_session(:return_to)
      |> configure_session(renew: true)
      |> redirect(to: ~p"/#{organization.account.handle}")
    else
      {:error, :identity_not_linked} ->
        conn
        |> put_flash(
          :error,
          gettext(
            "Sign in with your existing method first, then return to this page to connect your work identity."
          )
        )
        |> redirect(to: ~p"/auth/login")

      {:error, :membership_revoked} ->
        conn
        |> put_flash(
          :error,
          gettext(
            "Your organization access was removed. Contact your organization administrator."
          )
        )
        |> redirect(to: ~p"/auth/login")

      _ ->
        failed(conn)
    end
  end

  defp failed(conn) do
    conn
    |> put_flash(
      :error,
      gettext(
        "Organization sign-in is unavailable or could not be verified. Domain ownership may need to be verified again. Contact your organization administrator."
      )
    )
    |> redirect(to: ~p"/auth/login")
  end
end
