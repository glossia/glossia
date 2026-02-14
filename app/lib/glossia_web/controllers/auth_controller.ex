defmodule GlossiaWeb.AuthController do
  use GlossiaWeb, :controller

  alias Glossia.Auth
  alias Glossia.Accounts

  @dev_routes Application.compile_env(:glossia, :dev_routes, false)

  def login(conn, _params) do
    render(conn, :login, dev_routes: @dev_routes)
  end

  def request(conn, %{"provider" => provider}) do
    provider = parse_provider!(provider)

    case Auth.authorize_url(provider) do
      {:ok, %{url: url, session_params: session_params}} ->
        conn
        |> put_session(:oauth_session_params, session_params)
        |> redirect(external: url)

      {:error, _error} ->
        conn
        |> put_flash(:error, gettext("Failed to start authentication. Please try again."))
        |> redirect(to: ~p"/auth/login")
    end
  end

  def callback(conn, %{"provider" => provider} = params) do
    provider = parse_provider!(provider)
    session_params = get_session(conn, :oauth_session_params)
    conn = delete_session(conn, :oauth_session_params)

    case Auth.callback(provider, params, session_params) do
      {:ok, oauth_response} ->
        case Accounts.find_or_create_user_from_oauth(provider, oauth_response) do
          {:ok, user} ->
            return_to = get_session(conn, :return_to)

            conn
            |> delete_session(:return_to)
            |> put_session(:user_id, user.id)
            |> configure_session(renew: true)
            |> redirect(
              to: return_to || if(user.account.has_access, do: ~p"/dashboard", else: ~p"/billing")
            )

          {:error, _changeset} ->
            conn
            |> put_flash(:error, gettext("There was a problem creating your account. Please try again."))
            |> redirect(to: ~p"/auth/login")
        end

      {:error, _error} ->
        conn
        |> put_flash(:error, gettext("Authentication failed. Please try again."))
        |> redirect(to: ~p"/auth/login")
    end
  end

  def dev_login(conn, _params) do
    case Glossia.Repo.get_by(Glossia.Accounts.User, email: "dev@glossia.ai") do
      nil ->
        conn
        |> put_flash(:error, gettext("Dev user not found. Run: mix run priv/repo/seeds.exs"))
        |> redirect(to: ~p"/auth/login")

      user ->
        return_to = get_session(conn, :return_to)

        conn
        |> delete_session(:return_to)
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> redirect(to: return_to || if(user.account.has_access, do: ~p"/dashboard", else: ~p"/billing"))
    end
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end

  defp parse_provider!("github"), do: :github
  defp parse_provider!("gitlab"), do: :gitlab

  defp parse_provider!(_),
    do: raise(Glossia.Auth.InvalidProviderError, message: "invalid provider")
end
