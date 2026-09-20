defmodule GlossiaWeb.PublicPageChallengeController do
  @moduledoc ~S"""
  Serves the Cloudflare Turnstile interstitial that gates anonymous
  entry into public-account and public-project dashboards. Paired with
  `GlossiaWeb.Plugs.PublicPageChallengePlug` on the dead-render path and
  `GlossiaWeb.LiveHooks.PublicPageChallenge` on the connected LiveView
  mount.

  ## Endpoints

    * `GET /turnstile-challenge` — renders the challenge page. When the
      challenge is not required (kill switch pulled, visitor already
      signed in, or session already carries a fresh verification) it
      redirects to the captured return path — or `/` when none was
      captured.

    * `POST /turnstile-challenge/verify` — accepts the token the
      Turnstile widget produced (`cf-turnstile-response`), verifies it
      against Cloudflare's siteverify with the expected action pinned
      to `public_page_challenge`, and on success stores a short-lived
      verification timestamp in the signed Phoenix session so
      subsequent dashboard requests can proceed. Rate limited per
      client IP; a failed verification re-renders the challenge page
      with an error, does NOT clear the return path.

  Response cache is disabled on both endpoints so a browser's back
  button cannot serve a stale success page after the session is
  cleared. Return paths are validated as local (single leading slash,
  no scheme, no protocol-relative form) before honouring them.
  """
  use GlossiaWeb, :controller

  alias Glossia.Cloudflare.Turnstile.PublicPage
  alias Glossia.RateLimiter
  alias GlossiaWeb.ClientIP
  alias GlossiaWeb.Plugs.PublicPageChallengePlug

  require Logger

  # The challenge template is a full HTML document (its own <html>,
  # <head>, and <body>), so the browser pipeline's default layouts would
  # wrap it in a second <html> and break rendering. Clear both.
  plug :put_root_layout, false
  plug :put_layout, false

  @expected_action "public_page_challenge"
  # Bounds how many verify attempts one IP can burn per minute. Sized so
  # a real user with a fat-fingered Turnstile challenge (three or four
  # retries) never trips it, and so a scraper trying to grind tokens
  # against Cloudflare's siteverify from one IP burns out in seconds.
  @verify_rate_limit 30

  @doc "URL of the verify endpoint. Resolved through `~p` so a rename or removal fails at compile time."
  def verify_path, do: ~p"/turnstile-challenge/verify"

  def show(conn, params) do
    conn = persist_return_to(conn, params["return_to"])

    cond do
      not PublicPage.required?() ->
        conn |> no_store() |> redirect(to: safe_return_to(conn))

      PublicPageChallengePlug.signed_in?(conn) ->
        conn |> no_store() |> redirect(to: safe_return_to(conn))

      PublicPageChallengePlug.verified_within_freshness?(conn) ->
        conn |> no_store() |> redirect(to: safe_return_to(conn))

      true ->
        conn |> no_store() |> render_challenge(nil)
    end
  end

  def verify(conn, params) do
    # The failure re-render reads `return_to` from the session (populated
    # either by the plug or by the show controller from a `?return_to=`
    # query). A visitor whose only return_to source was the POSTed form
    # field needs it persisted here too so the retry preserves the
    # original destination.
    conn = persist_return_to(conn, params["return_to"])

    # `required?: true` is passed explicitly so that flipping the signup
    # Turnstile config (or leaving the public-page enable flag unset) can
    # NEVER short-circuit `PublicPage.verify/2` into a bare `:ok`. This
    # gate stands independent of the signup gate; it lives or dies on
    # its own config and its own siteverify round trip.
    with :ok <- check_rate_limit(conn),
         :ok <-
           PublicPage.verify(params["cf-turnstile-response"],
             required?: true,
             expected_action: @expected_action
           ) do
      conn
      |> mark_verified()
      |> no_store()
      |> redirect(to: safe_return_to(conn, params["return_to"]))
    else
      {:error, :rate_limited} ->
        conn
        |> put_status(:too_many_requests)
        |> no_store()
        |> render_challenge(gettext("Too many attempts. Please wait a moment and try again."))

      {:error, reason} ->
        Logger.info("public_page_challenge verification rejected", reason: inspect(reason))

        conn
        |> put_status(:bad_request)
        |> no_store()
        |> render_challenge(gettext("Verification failed. Please try again."))
    end
  end

  # The plug on the dashboard scopes stashes the return path in the
  # signed Phoenix session; the LiveView on_mount hook cannot do that
  # (no Plug.Conn) so it appends `?return_to=<encoded>` to the challenge
  # URL instead. Both entry vectors — query string on GET, form field on
  # POST — funnel through this helper so the session key is populated
  # identically, and hostile inputs (non-local, protocol-relative,
  # control-character-carrying) drop silently.
  defp persist_return_to(conn, raw) when is_binary(raw) and raw != "" do
    if local_path?(raw) do
      put_session(conn, PublicPageChallengePlug.return_to_key(), raw)
    else
      conn
    end
  end

  defp persist_return_to(conn, _), do: conn

  # Common render payload for the show endpoint's initial render and both
  # verify failure branches. Keeping the assigns in one place means a new
  # widget field, an assign rename, or an added CSP hint changes one call
  # instead of three.
  defp render_challenge(conn, error) do
    render(conn, :show,
      turnstile_required?: PublicPage.required?(),
      turnstile_site_key: PublicPage.site_key(),
      expected_action: @expected_action,
      verify_path: verify_path(),
      return_to: get_session(conn, PublicPageChallengePlug.return_to_key()),
      error: error
    )
  end

  defp check_rate_limit(conn) do
    key = "public-page-challenge:verify:ip:#{ClientIP.value(conn)}"

    case RateLimiter.hit(key, :timer.minutes(1), @verify_rate_limit) do
      {:allow, _} -> :ok
      {:deny, _} -> {:error, :rate_limited}
    end
  end

  defp mark_verified(conn) do
    now = System.system_time(:second)

    conn
    |> put_session(PublicPageChallengePlug.session_key(), now)
    |> delete_session(PublicPageChallengePlug.return_to_key())
    |> configure_session(renew: true)
  end

  defp no_store(conn) do
    conn
    |> put_resp_header("cache-control", "no-store, no-cache, must-revalidate, max-age=0")
    |> put_resp_header("pragma", "no-cache")
  end

  # A `return_to` value only survives the round trip when it is a local
  # path: single leading `/`, no scheme, no protocol-relative `//` form.
  # Anything else falls back to `/`.
  defp safe_return_to(conn, override \\ nil) do
    candidate =
      override ||
        get_session(conn, PublicPageChallengePlug.return_to_key()) ||
        "/"

    if local_path?(candidate), do: candidate, else: "/"
  end

  # Phoenix's `redirect(to: path)` raises `Plug.Conn.InvalidHeaderError`
  # when the path carries a control character (CR/LF/tab, NUL, or any
  # byte < 0x20 / 0x7f), and the protocol-relative `//` and `/\` forms
  # let a bare `Location` header point off-origin. Reject all of that
  # here and fall back to `/` rather than blowing up mid-verify.
  defp local_path?("//" <> _), do: false
  defp local_path?("/\\" <> _), do: false

  defp local_path?("/" <> _ = path) when is_binary(path) do
    not Regex.match?(~r/[\x00-\x1f\x7f\\]/, path)
  end

  defp local_path?(_), do: false

  @doc "Freshness window used by the plug + on_mount, exposed here for tests."
  def freshness_seconds, do: PublicPage.freshness_seconds()
end
