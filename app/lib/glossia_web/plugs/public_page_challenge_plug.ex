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
  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn

  alias Glossia.Cloudflare.Turnstile.PublicPage

  @session_key "public_page_challenge_verified_at"
  @return_to_key "public_page_return_to"
  @challenge_path "/turnstile-challenge"

  @doc "Session key holding the last verification timestamp (unix seconds)."
  def session_key, do: @session_key

  @doc "Session key holding the return path captured before the challenge."
  def return_to_key, do: @return_to_key

  @doc "URL of the challenge page itself. Kept in one place so callers stay honest."
  def challenge_path, do: @challenge_path

  def init(opts), do: opts

  def call(conn, _opts) do
    cond do
      not PublicPage.required?() ->
        conn

      authenticated?(conn) ->
        conn

      verified_within_freshness?(conn) ->
        conn

      true ->
        conn
        |> put_session(@return_to_key, return_to(conn))
        |> redirect(to: @challenge_path)
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

  defp fresh?(nil), do: false

  defp fresh?(ts) when is_integer(ts) do
    System.system_time(:second) - ts <= PublicPage.freshness_seconds()
  end

  defp fresh?(_), do: false

  # Glossia stores the signed-in user's id directly on the session, not a
  # session token (see GlossiaWeb.PlatformHooks.on_mount(:load_user, ...)
  # and GlossiaWeb.Plugs.Auth). Presence of a non-nil `user_id` is enough
  # to treat the visitor as authenticated for the purposes of skipping the
  # public-page gate — the dashboard's own authorization still runs after.
  defp authenticated?(conn) do
    case get_session(conn, "user_id") do
      id when not is_nil(id) -> true
      _ -> false
    end
  end

  defp return_to(conn) do
    case conn.query_string do
      "" -> conn.request_path
      qs -> conn.request_path <> "?" <> qs
    end
  end
end
