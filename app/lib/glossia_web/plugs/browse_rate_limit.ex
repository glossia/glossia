defmodule GlossiaWeb.Plugs.BrowseRateLimit do
  @moduledoc """
  Rate limits HTML browsing of the public-account platform scope: the
  account, project, translations, session, voice, terminology, discussion
  and ticket routes served under `pipe_through [:browser, :platform,
  :browse_rate_limit]`. The authenticated-only dashboard settings scope
  (tokens, OAuth apps, LLM models, project settings) is on a separate
  pipeline and is not rate-limited here.

  Anonymous readers can reach these pages when the account is public, so a
  crawler that walks the tree could otherwise drive real translation
  gateway cost and DB load. Signed-in visitors are keyed by user id so
  many people behind one NAT or CGNAT egress each get their own bucket;
  anonymous visitors fall back to a per-IP bucket, which is the actual
  crawler backstop. The 429 response is a themed, localized HTML page —
  browsers should not receive a bare JSON envelope on this pipeline.

  Only the HTTP request that mounts a LiveView is rate-limited; LiveView
  events on the WebSocket bypass this. That is currently sufficient
  because every cost-bearing action is guarded by write authorization
  which anonymous visitors never satisfy — if we ever expose an
  anonymous-invokable expensive event, it needs its own bucket inside its
  `handle_event`.
  """

  @config GlossiaWeb.Plugs.RateLimit.init(
            key_prefix: "browse",
            scale: 60_000,
            limit: 1_000,
            by: :user,
            format: :html
          )

  def init([]), do: []

  def init(opts) do
    raise ArgumentError,
          "GlossiaWeb.Plugs.BrowseRateLimit takes no options; got #{inspect(opts)}. " <>
            "Change the compile-time @config in the module instead."
  end

  def call(conn, _opts) do
    GlossiaWeb.Plugs.RateLimit.call(conn, @config)
  end
end
