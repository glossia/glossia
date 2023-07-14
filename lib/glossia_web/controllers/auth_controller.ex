defmodule GlossiaWeb.AuthController do
  use GlossiaWeb, :controller
  plug Ueberauth

  alias Ueberauth.Strategy.Helpers
  alias Glossia.Auth

  def login(conn, _params) do
    render(conn, :login)
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
  end

  def callback(%{assigns: %{ueberauth_failure: error}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Auth.find_or_create(auth) do
      {:ok, user} ->
        conn
        |> GlossiaWeb.UserAuth.log_in_user(user)
        |> put_flash(:info, "Successfully authenticated.")
        |> put_session(:current_user, user)
        |> configure_session(renew: true)
        |> redirect(to: "/")

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end
end
