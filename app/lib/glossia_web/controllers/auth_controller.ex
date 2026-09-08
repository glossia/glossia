defmodule GlossiaWeb.AuthController do
  use GlossiaWeb, :controller

  alias Glossia.Auth
  alias Glossia.Accounts
  alias Glossia.Cloudflare.Turnstile
  alias Glossia.Events
  alias GlossiaWeb.SignupProtection

  @dev_routes Application.compile_env(:glossia, :dev_routes, false)

  # The Turnstile-verified flag is written on the sign-up form submit
  # and consumed in the OAuth callback; anything older than this window
  # forces the user through the widget again.
  @signup_gate_ttl_seconds 15 * 60

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
       @oauth_rate_limit
       when action in [:request, :callback, :dev_login, :verify_signup_gate]

  def login(conn, _params) do
    render_auth_entry(conn,
      mode: :login,
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
      mode: :signup,
      page_title: gettext("Sign up"),
      title: gettext("Sign up for Glossia"),
      subtitle: gettext("Choose a provider to create your account and start using Glossia."),
      switch_prompt: gettext("Already have an account?"),
      switch_href: ~p"/auth/login",
      switch_label: gettext("Log in")
    )
  end

  defp render_auth_entry(conn, assigns) do
    turnstile_required? = assigns[:mode] == :signup and Turnstile.required?()

    conn
    |> put_layout(false)
    |> render(:login,
      dev_routes: @dev_routes,
      providers: supported_login_providers(),
      mode: assigns[:mode],
      turnstile_required?: turnstile_required?,
      turnstile_site_key: turnstile_required? && Turnstile.site_key(),
      csrf_token: Plug.CSRFProtection.get_csrf_token(),
      page_title: assigns[:page_title],
      title: assigns[:title],
      subtitle: assigns[:subtitle],
      switch_prompt: assigns[:switch_prompt],
      switch_href: assigns[:switch_href],
      switch_label: assigns[:switch_label]
    )
  end

  @doc """
  Sign-up gate. The sign-up form posts here per provider button; on
  success we stamp `:signup_gate_verified_at` in the session and hand
  off to the normal OAuth start endpoint. On failure we bounce back to
  `/signup` with a flash message.

  When Turnstile is not required (dev, kill switch on) this becomes a
  pass-through — the session flag is still written so the OAuth
  callback's gate check is uniform across environments.
  """
  def verify_signup_gate(conn, %{"provider" => provider_param} = params) do
    case safe_parse_provider(provider_param) do
      {:ok, provider} ->
        if provider in supported_login_providers() do
          case SignupProtection.verify(session_bucket_key(conn), params, "signup") do
            :ok ->
              conn
              |> put_session(:signup_gate_verified_at, System.system_time(:second))
              |> redirect(to: ~p"/auth/#{provider}")

            {:error, reason} ->
              conn
              |> put_flash(:error, signup_gate_error_message(reason))
              |> redirect(to: ~p"/signup")
          end
        else
          conn
          |> put_flash(:error, gettext("That sign-in method is not available."))
          |> redirect(to: ~p"/signup")
        end

      :error ->
        conn
        |> put_flash(:error, gettext("That sign-in method is not available."))
        |> redirect(to: ~p"/signup")
    end
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
    gate_verified? = signup_gate_verified?(conn)

    # Consume the one-shot flags on every code path so a solved
    # Turnstile can't be replayed against a second provider start.
    conn =
      conn
      |> delete_session(:oauth_session_params)
      |> delete_session(:signup_gate_verified_at)

    case Auth.callback(provider, params, session_params) do
      {:ok, oauth_response} ->
        provider_uid = to_string(oauth_response.user["sub"])

        cond do
          Accounts.get_identity(provider, provider_uid) != nil ->
            complete_login(conn, provider, oauth_response)

          gate_verified? ->
            complete_signup(conn, provider, oauth_response)

          true ->
            # The user reached the callback without a fresh sign-up
            # gate. Bounce them to /signup so they see the widget
            # instead of silently failing.
            conn
            |> put_flash(
              :error,
              gettext("Please complete the sign-up challenge before continuing.")
            )
            |> redirect(to: ~p"/signup")
        end

      {:error, _error} ->
        conn
        |> put_flash(:error, gettext("Authentication failed. Please try again."))
        |> redirect(to: ~p"/auth/login")
    end
  end

  defp complete_login(conn, provider, oauth_response) do
    case Accounts.find_or_create_user_from_oauth(provider, oauth_response,
           locale: conn.assigns[:locale]
         ) do
      {:ok, user} -> finalize_session(conn, user, "user.signed_in", "Signed in")
      {:error, _changeset} -> callback_error(conn)
    end
  end

  defp complete_signup(conn, provider, oauth_response) do
    case Accounts.find_or_create_user_from_oauth(provider, oauth_response,
           locale: conn.assigns[:locale]
         ) do
      {:ok, user} -> finalize_session(conn, user, "user.signed_up", "Signed up")
      {:error, _changeset} -> callback_error(conn)
    end
  end

  defp finalize_session(conn, user, event_type, summary) do
    return_to = get_session(conn, :return_to)

    Events.emit(event_type, user.account, user,
      resource_type: "user",
      resource_id: to_string(user.id),
      summary: summary
    )

    conn
    |> delete_session(:return_to)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
    |> redirect(to: return_to || ~p"/dashboard")
  end

  defp callback_error(conn) do
    conn
    |> put_flash(:error, gettext("There was a problem creating your account. Please try again."))
    |> redirect(to: ~p"/auth/login")
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

  defp signup_gate_verified?(conn) do
    if Turnstile.required?() do
      case get_session(conn, :signup_gate_verified_at) do
        ts when is_integer(ts) ->
          System.system_time(:second) - ts <= @signup_gate_ttl_seconds

        _ ->
          false
      end
    else
      # Off in dev / kill switch flipped — the gate is not enforced.
      true
    end
  end

  defp signup_gate_error_message(:rate_limited),
    do:
      gettext(
        "Too many sign-up attempts from this session. Please wait a few minutes and try again."
      )

  defp signup_gate_error_message(:missing_session),
    do: gettext("Your session expired. Please reload the page and try again.")

  defp signup_gate_error_message(:turnstile_failed),
    do: gettext("The sign-up challenge did not pass. Please try again.")

  defp signup_gate_error_message(:misconfigured),
    do:
      gettext(
        "Sign-up is temporarily unavailable while we fix a configuration issue. Please try again shortly."
      )

  # The raw, unmasked CSRF token Phoenix stashes in the session. Unlike
  # `Plug.CSRFProtection.get_csrf_token/0` (which re-masks with fresh
  # random bytes on every call, defeating any bucket keyed on it), this
  # value is stable across a browser session, which is exactly what the
  # registration rate-limit bucket needs to fence a persistent client.
  defp session_bucket_key(conn), do: get_session(conn, "_csrf_token")

  defp safe_parse_provider(provider) do
    {:ok, parse_provider!(provider)}
  rescue
    Glossia.Auth.InvalidProviderError -> :error
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
