defmodule GlossiaWeb.AuthController do
  use GlossiaWeb, :controller

  alias Glossia.Auth
  alias Glossia.Accounts
  alias Glossia.Events

  @dev_routes Application.compile_env(:glossia, :dev_routes, false)

  @login_rate_limit [
    key_prefix: "auth_login_page",
    scale: :timer.minutes(1),
    limit: 120,
    by: :ip,
    format: :text
  ]

  @oauth_rate_limit [
    key_prefix: "auth_oauth_flow",
    scale: :timer.minutes(1),
    limit: 20,
    by: :ip,
    format: :text
  ]

  plug GlossiaWeb.Plugs.RateLimit, @login_rate_limit when action in [:login, :signup]

  plug GlossiaWeb.Plugs.RateLimit,
       @oauth_rate_limit when action in [:request, :callback, :dev_login]

  def login(conn, _params) do
    render_auth_entry(conn,
      page_title: gettext("Log in"),
      title: gettext("Log in to Glossia"),
      subtitle: gettext("Welcome back. Choose a sign-in method to continue."),
      switch_prompt: gettext("New to Glossia?"),
      switch_href: ~p"/signup",
      switch_label: gettext("Sign up")
    )
  end

  def signup(conn, _params) do
    render_auth_entry(conn,
      page_title: gettext("Sign up"),
      title: gettext("Sign up for Glossia"),
      subtitle: gettext("Choose a provider to create your account and start using Glossia."),
      switch_prompt: gettext("Already have an account?"),
      switch_href: ~p"/auth/login",
      switch_label: gettext("Log in")
    )
  end

  defp render_auth_entry(conn, assigns) do
    conn
    |> put_layout(false)
    |> render(:login,
      dev_routes: @dev_routes,
      providers: supported_login_providers(),
      page_title: assigns[:page_title],
      title: assigns[:title],
      subtitle: assigns[:subtitle],
      switch_prompt: assigns[:switch_prompt],
      switch_href: assigns[:switch_href],
      switch_label: assigns[:switch_label]
    )
  end

  def request(conn, %{"provider" => provider}) do
    provider = parse_provider!(provider)

    if provider in supported_login_providers() do
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
    else
      conn
      |> put_flash(:error, gettext("That sign-in method is not available."))
      |> redirect(to: ~p"/auth/login")
    end
  end

  def callback(conn, %{"provider" => provider} = params) do
    provider = parse_provider!(provider)
    session_params = get_session(conn, :oauth_session_params)
    conn = delete_session(conn, :oauth_session_params)

    case Auth.callback(provider, params, session_params) do
      {:ok, oauth_response} ->
        # New accounts start in the language the browser asked for, which the
        # locale plug has already resolved for this request.
        case Accounts.find_or_create_user_from_oauth(provider, oauth_response,
               locale: conn.assigns[:locale]
             ) do
          {:ok, user} ->
            return_to = get_session(conn, :return_to)

            Events.emit("user.signed_in", user.account, user,
              resource_type: "user",
              resource_id: to_string(user.id),
              summary: "Signed in"
            )

            conn
            |> delete_session(:return_to)
            |> put_session(:user_id, user.id)
            |> configure_session(renew: true)
            |> redirect(to: return_to || ~p"/dashboard")

          {:error, _changeset} ->
            conn
            |> put_flash(
              :error,
              gettext("There was a problem creating your account. Please try again.")
            )
            |> redirect(to: ~p"/auth/login")
        end

      {:error, _error} ->
        conn
        |> put_flash(:error, gettext("Authentication failed. Please try again."))
        |> redirect(to: ~p"/auth/login")
    end
  end

  def dev_login(conn, _params) do
    case Glossia.Accounts.User
         |> Glossia.Repo.get_by(email: "dev@glossia.ai")
         |> then(fn
           nil -> nil
           user -> Glossia.Repo.preload(user, :account)
         end) do
      nil ->
        conn
        |> put_flash(:error, gettext("Test user not found. Run: mix run priv/repo/seeds.exs"))
        |> redirect(to: ~p"/auth/login")

      user ->
        return_to = get_session(conn, :return_to)

        Events.emit("user.signed_in", user.account, user,
          resource_type: "user",
          resource_id: to_string(user.id),
          summary: "Signed in (dev)"
        )

        conn
        |> delete_session(:return_to)
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> redirect(to: return_to || ~p"/dashboard")
    end
  end

  def logout(conn, _params) do
    if user = conn.assigns[:current_user] do
      Events.emit("user.signed_out", user.account, user,
        resource_type: "user",
        resource_id: to_string(user.id),
        summary: "Signed out"
      )
    end

    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end

  defp parse_provider!("github"), do: :github
  defp parse_provider!("gitlab"), do: :gitlab

  defp parse_provider!(_),
    do: raise(Glossia.Auth.InvalidProviderError, message: "invalid provider")

  defp supported_login_providers do
    :glossia
    |> Application.get_env(:oauth_providers, [])
    |> Keyword.take([:github, :gitlab])
    |> Keyword.keys()
  end
end
