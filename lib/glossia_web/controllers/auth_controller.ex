defmodule GlossiaWeb.Controllers.AuthController do
  use GlossiaWeb.Helpers.App, :controller

  plug Ueberauth

  alias Ueberauth.Strategy.Helpers
  alias Glossia.Auth, as: Auth
  alias GlossiaWeb.Support.PathRememberer

  @remember_me_cookie "_glossia_web_user_remember_me"

  def login(conn, _params) do
    if GlossiaWeb.Auth.user_authenticated?(conn) do
      conn |> redirect_from_marketing_or_after_login
    else
      conn
      |> put_layout(html: {GlossiaWeb.Layouts.Auth, :empty})
      |> put_open_graph_metadata(%{
        title: "Login",
        description: "Login to Glossia"
      })
      |> render(:login)
    end
  end

  defp redirect_from_marketing_or_after_login(conn) do
    user_return_to = PathRememberer.remembered_path(conn)

    if user_return_to do
      conn |> redirect(to: user_return_to)
    else
      user = GlossiaWeb.Auth.authenticated_user(conn)

      project =
        case user.last_visited_project_id do
          nil ->
            Glossia.Accounts.get_user_and_organization_accounts(user)
            |> Glossia.Projects.get_account_projects()
            |> List.first()

          last_visited_project_id ->
            Glossia.Projects.get_project_by_id(last_visited_project_id)
        end

      if project do
        account = Glossia.Accounts.get_user_account(user)
        conn |> redirect(to: ~p"/#{account.handle}/#{project.handle}")
      else
        conn |> redirect(to: ~p"/new")
      end
    end
  end

  def request(conn, _params) do
    render(conn, "request.html", callback_url: Helpers.callback_url(conn))
  end

  def logout(conn, _params) do
    user_token = get_session(conn, :user_token)
    user_token && Glossia.Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      GlossiaWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  def callback(%{assigns: %{ueberauth_failure: _error}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: ~p"/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Auth.find_or_create(auth) do
      {:ok, user} ->
        conn
        |> GlossiaWeb.Auth.log_in_user(user)
        |> put_flash(:info, "Successfully authenticated.")
        |> redirect_from_marketing_or_after_login()

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
