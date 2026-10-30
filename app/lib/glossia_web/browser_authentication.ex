defmodule GlossiaWeb.BrowserAuthentication do
  @moduledoc "Browser sign-in stops at MFA before exposing a usable user session."
  use GlossiaWeb, :verified_routes
  import Plug.Conn
  import Phoenix.Controller
  alias Glossia.Accounts.MFA

  def current_user(session) do
    user =
      MFA.session_user(
        session["impersonating_from"] || session["user_id"],
        session["browser_token"]
      )

    if session["impersonating_from"] do
      target = Glossia.Accounts.get_user(session["user_id"])

      if user && target && Glossia.Authz.authorize?(:admin_read, user, nil) &&
           not MFA.enabled?(target),
         do: target
    else
      user
    end
  end

  def sign_in(conn, user, return_to, organization_sso \\ nil) do
    MFA.revoke(get_session(conn, :browser_token))
    MFA.revoke(get_session(conn, :mfa_challenge))
    {context, token} = MFA.sign_in(user, organization_sso)

    conn =
      conn
      |> delete_session(:user_id)
      |> delete_session(:browser_token)
      |> delete_session(:organization_sso)
      |> delete_session(:impersonating_from)
      |> delete_session(:impersonation_reason)
      |> configure_session(renew: true)

    if context == "challenge" do
      conn
      |> put_session(:mfa_challenge, token)
      |> put_session(:return_to, return_to)
      |> redirect(to: ~p"/auth/mfa")
    else
      conn |> bind(user, token, organization_sso) |> redirect(to: return_to)
    end
  end

  def bind(conn, user, token, organization_sso) do
    Glossia.Events.emit("user.signed_in", user.account, user,
      resource_type: "user",
      resource_id: user.id,
      summary: "Signed in"
    )

    conn
    |> configure_session(renew: true)
    |> delete_session(:mfa_challenge)
    |> delete_session(:return_to)
    |> put_session(:user_id, user.id)
    |> put_session(:browser_token, token)
    |> put_session(:organization_sso, organization_sso)
    |> put_session(:live_socket_id, "user_sessions:#{user.id}")
  end
end
