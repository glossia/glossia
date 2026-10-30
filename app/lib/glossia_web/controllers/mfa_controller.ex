defmodule GlossiaWeb.MFAController do
  use GlossiaWeb, :controller
  alias Glossia.Accounts.MFA
  alias GlossiaWeb.BrowserAuthentication

  plug :private_response
  plug :require_user when action not in [:challenge, :verify]

  def challenge(conn, params) do
    if user = MFA.challenge(get_session(conn, :mfa_challenge)) do
      conn
      |> put_layout(false)
      |> render(:challenge, user: user, recovery: params["recovery"] == "true", error: nil)
    else
      redirect(conn, to: ~p"/auth/login")
    end
  end

  def verify(conn, params) do
    token = get_session(conn, :mfa_challenge)
    recovery? = params["recovery"] == "true"

    case MFA.complete(token, params["mfa_code"], recovery?) do
      {:ok, user, session_token} ->
        return_to = get_session(conn, :return_to) || ~p"/dashboard"

        conn
        |> BrowserAuthentication.bind(user, session_token, MFA.organization_proof(session_token))
        |> redirect(to: return_to)

      {:error, :expired} ->
        conn |> delete_session(:mfa_challenge) |> redirect(to: ~p"/auth/login")

      {:error, reason} ->
        if user = MFA.challenge(token) do
          conn
          |> put_layout(false)
          |> put_status(:unprocessable_entity)
          |> render(:challenge,
            user: user,
            recovery: recovery?,
            error: error_message(reason)
          )
        else
          conn |> delete_session(:mfa_challenge) |> redirect(to: ~p"/auth/login")
        end
    end
  end

  def settings(conn, _params), do: render_settings(conn)

  def begin(conn, _params) do
    case MFA.begin_enrollment(conn.assigns.current_user, get_session(conn, :browser_token)) do
      {:ok, _factor} -> redirect(conn, to: ~p"/-/settings/security")
      {:error, reason} -> failure(conn, reason)
    end
  end

  def confirm(conn, params) do
    case MFA.confirm(
           conn.assigns.current_user,
           get_session(conn, :browser_token),
           params["mfa_code"]
         ) do
      {:ok, codes, token} -> show_recovery(conn, codes, token)
      {:error, reason} -> failure(conn, reason)
    end
  end

  def cancel(conn, _params) do
    MFA.cancel(conn.assigns.current_user, get_session(conn, :browser_token))
    redirect(conn, to: ~p"/-/settings/security")
  end

  def manage(conn, %{"operation" => operation} = params)
      when operation in ["regenerate", "disable"] do
    action = if operation == "regenerate", do: :regenerate, else: :disable
    code = String.trim(params["mfa_code"] || "")

    case MFA.manage(
           conn.assigns.current_user,
           get_session(conn, :browser_token),
           code,
           String.length(code) != 6,
           action
         ) do
      {:ok, [], token} ->
        conn
        |> put_session(:browser_token, token)
        |> put_flash(:info, gettext("Two-factor authentication disabled."))
        |> redirect(to: ~p"/-/settings/security")

      {:ok, codes, token} ->
        show_recovery(conn, codes, token)

      {:error, reason} ->
        failure(conn, reason)
    end
  end

  def manage(conn, _params), do: send_resp(conn, :bad_request, "Invalid MFA operation.")

  defp show_recovery(conn, codes, token) do
    conn
    |> put_session(:browser_token, token)
    |> put_layout(html: {GlossiaWeb.Layouts, :user_profile})
    |> render(:recovery,
      codes: codes,
      live_action: :security,
      breadcrumb_label: gettext("Security")
    )
  end

  defp render_settings(conn, error \\ nil) do
    user = conn.assigns.current_user
    factor = MFA.pending(user, get_session(conn, :browser_token))

    {key, qr} =
      if factor do
        uri = NimbleTOTP.otpauth_uri("Glossia:#{user.email}", factor.secret, issuer: "Glossia")
        {:ok, svg} = uri |> QRCode.create(:medium) |> QRCode.render(:svg)

        {Base.encode32(factor.secret, padding: false),
         "data:image/svg+xml;base64," <> Base.encode64(svg)}
      else
        {nil, nil}
      end

    conn
    |> put_layout(html: {GlossiaWeb.Layouts, :user_profile})
    |> render(:settings,
      enabled: MFA.enabled?(user),
      setup_key: key,
      qr: qr,
      error: error,
      live_action: :security,
      breadcrumb_label: gettext("Security")
    )
  end

  defp failure(conn, :reauthenticate) do
    conn
    |> put_session(:return_to, ~p"/-/settings/security")
    |> put_flash(:info, gettext("Sign in again before changing two-factor authentication."))
    |> redirect(to: ~p"/auth/login")
  end

  defp failure(conn, reason),
    do: conn |> put_status(:unprocessable_entity) |> render_settings(error_message(reason))

  defp error_message(:rate_limited),
    do: gettext("Too many attempts. Wait five minutes and try again.")

  defp error_message(_),
    do: gettext("That code is invalid or has already been used. Try a new code.")

  defp require_user(conn, _) do
    if get_session(conn, :impersonating_from) do
      conn
      |> send_resp(:forbidden, "Factor management is unavailable while impersonating.")
      |> halt()
    else
      GlossiaWeb.Plugs.RequireAuth.call(conn, [])
    end
  end

  defp private_response(conn, _) do
    conn
    |> put_resp_header("cache-control", "private, no-store")
    |> put_resp_header("referrer-policy", "no-referrer")
    |> assign(:page_title, gettext("Two-factor authentication"))
  end
end
