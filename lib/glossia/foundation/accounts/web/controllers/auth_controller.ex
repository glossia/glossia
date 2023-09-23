defmodule Glossia.Foundation.Accounts.Web.Controllers.AuthController do
  use Glossia.Foundation.Application.Web.Helpers.App, :controller

  plug Ueberauth

  alias Ueberauth.Strategy.Helpers
  alias Glossia.Foundation.Auth.Core, as: Auth

  @remember_me_cookie "_glossia_web_user_remember_me"

  def login(conn, _params) do
    conn
    |> put_open_graph_metadata(%{
      title: "Login",
      description: "Login to Glossia"
    })
    |> render(:login)
  end

  def request(conn, _params) do
    render(conn, "request.html", callback_url: Helpers.callback_url(conn))
  end

  def logout(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> clear_session()
    |> redirect(to: "/")
    |> halt()

    user_token = get_session(conn, :user_token)
    user_token && Glossia.Foundation.Accounts.Core.delete_user_session_token(user_token)

    # TODO
    # if live_socket_id = get_session(conn, :live_socket_id) do
    #   TestWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    # end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  def callback(%{assigns: %{ueberauth_failure: _error}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Auth.find_or_create(auth) do
      {:ok, user} ->
        conn
        |> Glossia.Foundation.Accounts.Web.Auth.log_in_user(user)
        |> put_flash(:info, "Successfully authenticated.")

        # _ ->
        #   conn
        #   |> put_flash(:error, "Error while authenticating.")
        #   |> redirect(to: "/")
    end
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
