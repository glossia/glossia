defmodule GlossiaWeb.AuthController do
  use GlossiaWeb, :controller

  alias Glossia.Auth
  alias Glossia.Accounts
  alias Glossia.Cloudflare.Turnstile
  alias Glossia.Events
  alias Glossia.Interest
  alias GlossiaWeb.SignupProtection

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

  plug GlossiaWeb.Plugs.RateLimit,
       [
         key_prefix: "signup_interest",
         scale: :timer.minutes(10),
         limit: 5,
         by: :ip,
         format: :text
       ]
       when action == :show_interest

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
      switch_label: gettext("Show interest")
    )
  end

  def signup(conn, _params) do
    render_interest(conn, Interest.changeset(%{}))
  end

  defp render_interest(conn, changeset) do
    render_auth_entry(conn,
      mode: :signup,
      page_title: gettext("Show interest"),
      title: gettext("Interested in Glossia?"),
      subtitle:
        gettext(
          "We’re onboarding teams gradually. Leave your email and we’ll get back to you to help you get started."
        ),
      interest_form: Phoenix.Component.to_form(changeset, as: :interest),
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
      interest_form: assigns[:interest_form],
      providers: supported_login_providers(),
      organization_form: Phoenix.Component.to_form(%{}, as: :organization),
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

  def show_interest(conn, params) do
    changeset = Interest.changeset(params["interest"] || %{})

    if changeset.valid? do
      with :ok <- SignupProtection.verify(session_bucket_key(conn), params, "signup"),
           {:ok, _metadata} <- Interest.deliver(changeset) do
        conn
        |> put_flash(
          :info,
          gettext(
            "Thanks for your interest! We’ll get back to you by email to help you get started."
          )
        )
        |> redirect(to: ~p"/signup")
      else
        {:error, reason} when is_atom(reason) ->
          conn
          |> put_flash(:error, signup_gate_error_message(reason))
          |> render_interest(changeset)

        {:error, _reason} ->
          conn
          |> put_status(:service_unavailable)
          |> put_flash(
            :error,
            gettext("We couldn’t send your request. Please try again in a moment.")
          )
          |> render_interest(changeset)
      end
    else
      conn
      |> put_status(:unprocessable_entity)
      |> render_interest(%{changeset | action: :validate})
    end
  end

  # Old signup forms and bookmarks must never enable account creation.
  def verify_signup_gate(conn, _params) do
    conn
    |> delete_session(:signup_gate_verified_at)
    |> redirect(to: ~p"/signup")
  end

  def request(conn, %{"provider" => provider}) do
    conn = delete_session(conn, :organization_auth)
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

    # Clear authentication state, including signup grants issued before
    # public registration was replaced by the interest form.
    conn =
      conn
      |> delete_session(:oauth_session_params)
      |> delete_session(:signup_gate_verified_at)

    case Auth.callback(provider, params, session_params) do
      {:ok, oauth_response} ->
        case sign_in(provider, oauth_response, conn) do
          {:ok, user, organization} ->
            conn
            |> put_session(
              :organization_sso,
              Glossia.OrganizationAuthentication.session_proof(organization, user)
            )
            |> finalize_session(user, "user.signed_in", "Signed in", true)

          {:ok, user} ->
            finalize_session(conn, user, "user.signed_in", "Signed in")

          {:error, :not_registered} ->
            conn
            |> put_flash(
              :info,
              gettext("We’re onboarding teams gradually. Leave your email to show your interest.")
            )
            |> redirect(to: ~p"/signup")

          {:error, :identity_not_linked} ->
            conn
            |> put_flash(
              :error,
              gettext(
                "Sign in with your existing method first, then return to this page to connect your work identity."
              )
            )
            |> redirect(to: ~p"/auth/login")

          {:error, _reason} ->
            callback_error(conn)
        end

      {:error, _error} ->
        conn
        |> put_flash(:error, gettext("Authentication failed. Please try again."))
        |> redirect(to: ~p"/auth/login")
    end
  end

  defp sign_in(:google, response, conn) do
    case Glossia.OrganizationAuthentication.for_email(response.user["email"]) do
      %{auth_provider: "google"} = organization ->
        with {:ok, user} <-
               Glossia.OrganizationAuthentication.sign_in(organization, response,
                 link_user_id: conn.assigns[:current_user] && conn.assigns.current_user.id
               ) do
          {:ok, user, organization}
        end

      _ ->
        Accounts.sign_in_user_from_oauth(:google, response)
    end
  end

  defp sign_in(provider, response, _conn),
    do: Accounts.sign_in_user_from_oauth(provider, response)

  defp finalize_session(conn, user, event_type, summary, organization_sign_in? \\ false) do
    return_to = get_session(conn, :return_to)
    conn = if organization_sign_in?, do: conn, else: delete_session(conn, :organization_sso)

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
    |> put_flash(:error, gettext("There was a problem signing you in. Please try again."))
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
        |> delete_session(:organization_sso)
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

  defp signup_gate_error_message(:rate_limited),
    do: gettext("Too many requests from this session. Please wait a few minutes and try again.")

  defp signup_gate_error_message(:missing_session),
    do: gettext("Your session expired. Please reload the page and try again.")

  defp signup_gate_error_message(:turnstile_failed),
    do: gettext("The verification challenge did not pass. Please try again.")

  defp signup_gate_error_message(:misconfigured),
    do:
      gettext(
        "The interest form is temporarily unavailable while we fix a configuration issue. Please try again shortly."
      )

  # The raw, unmasked CSRF token Phoenix stashes in the session. Unlike
  # `Plug.CSRFProtection.get_csrf_token/0` (which re-masks with fresh
  # random bytes on every call, defeating any bucket keyed on it), this
  # value is stable across a browser session, which is exactly what the
  # registration rate-limit bucket needs to fence a persistent client.
  defp session_bucket_key(conn), do: get_session(conn, "_csrf_token")

  defp parse_provider!("google"), do: :google
  defp parse_provider!("github"), do: :github
  defp parse_provider!("gitlab"), do: :gitlab

  defp parse_provider!(_),
    do: raise(Glossia.Auth.InvalidProviderError, message: "invalid provider")

  defp supported_login_providers do
    :glossia
    |> Application.get_env(:oauth_providers, [])
    |> Keyword.take([:github, :gitlab, :google])
    |> Keyword.keys()
  end
end
