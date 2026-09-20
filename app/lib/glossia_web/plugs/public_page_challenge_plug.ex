defmodule GlossiaWeb.Plugs.PublicPageChallengePlug do
  @moduledoc ~S"""
  Gates the dead-render entry to a public-account or public-project
  dashboard page behind a Cloudflare Turnstile challenge. Paired with
  `GlossiaWeb.LiveHooks.PublicPageChallenge` on the connected LiveView
  mount so a client that skips the dead render cannot bypass the gate.

  A request passes without a challenge when:

    * `Glossia.Cloudflare.Turnstile.PublicPage.required?/0` is false —
      either the compile-time env flag is off, or an operator has
      pulled the `:public_page_challenge_kill_switch` FunWithFlags
      flag.

    * The session already carries a signed `user_id`, meaning the
      visitor is signed in and the dashboard is already gated by its
      own authorization checks.

    * The session already carries a fresh
      `public_page_challenge_verified_at` timestamp inside the
      freshness window (see
      `Glossia.Cloudflare.Turnstile.PublicPage.freshness_seconds/0`).

  Otherwise the plug captures the request path + query string as
  `public_page_return_to` in the session and redirects to
  `/turnstile-challenge`. The controller there validates the return
  target as a local path before honouring it.
  """
  use GlossiaWeb, :verified_routes

  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn

  alias Glossia.Cloudflare.Turnstile.PublicPage

  @session_key "public_page_challenge_verified_at"
  @return_to_key "public_page_return_to"

  @doc "Session key holding the last verification timestamp (unix seconds)."
  def session_key, do: @session_key

  @doc "Session key holding the return path captured before the challenge."
  def return_to_key, do: @return_to_key

  @doc """
  URL of the challenge page itself. Resolved through `~p` so a rename or
  removal of the route in `router.ex` fails at compile time instead of
  quietly 404-ing at redirect time.
  """
  def challenge_path, do: ~p"/turnstile-challenge"

  def init(opts), do: opts

  def call(conn, _opts) do
    cond do
      not PublicPage.required?() ->
        conn

      signed_in?(conn) ->
        conn

      verified_within_freshness?(conn) ->
        conn

      true ->
        conn
        |> put_session(@return_to_key, return_to(conn))
        |> no_store()
        |> redirect(to: challenge_path())
        |> halt()
    end
  end

  @doc """
  Returns true when the session carries a `verified_at` timestamp that is
  still within the configured freshness window. Exposed so the matching
  on_mount hook can share the same predicate against the session map
  LiveView hands it.
  """
  def verified_within_freshness?(%Plug.Conn{} = conn) do
    conn |> get_session(@session_key) |> fresh?()
  end

  def verified_within_freshness?(session) when is_map(session) do
    session |> Map.get(@session_key) |> fresh?()
  end

  @doc """
  Signed-in predicate shared by the plug, controller, and LiveView
  on_mount hook. Glossia stores the signed-in user's id directly on the
  session (see `GlossiaWeb.PlatformHooks.on_mount(:load_user, ...)` and
  `GlossiaWeb.Plugs.Auth`). Presence of a non-nil `user_id` is enough to
  treat the visitor as authenticated for the purposes of skipping the
  public-page gate — the dashboard's own authorization still runs after.
  """
  def signed_in?(%Plug.Conn{} = conn) do
    conn |> get_session("user_id") |> present?()
  end

  def signed_in?(session) when is_map(session) do
    session |> Map.get("user_id") |> present?()
  end

  defp fresh?(nil), do: false

  defp fresh?(ts) when is_integer(ts) do
    System.system_time(:second) - ts <= PublicPage.freshness_seconds()
  end

  defp fresh?(_), do: false

  defp present?(nil), do: false
  defp present?(_), do: true

  # `no-store` on the redirect to keep browsers and intermediaries from
  # caching the 302 target. Without this a Safari history-back or an
  # intermediary that respects RFC 7234 heuristic staleness could serve a
  # cached location after the underlying session was invalidated.
  defp no_store(conn) do
    conn
    |> put_resp_header("cache-control", "no-store, no-cache, must-revalidate, max-age=0")
    |> put_resp_header("pragma", "no-cache")
  end

  defp return_to(conn) do
    case conn.query_string do
      "" -> conn.request_path
      qs -> conn.request_path <> "?" <> qs
    end
  end
end
