defmodule GlossiaWeb.Plugs.BrowseRateLimit do
  @moduledoc """
  Rate limits HTML browsing of the public-account platform scope: the
  account, project, translations, session, voice, terminology, discussion
  and ticket routes served under `pipe_through [:browser, :platform,
  :public_page_challenge, :browse_rate_limit]`. The authenticated-only
  dashboard settings scope (tokens, OAuth apps, LLM models, project
  settings) is on a separate pipeline and is not rate-limited here.

  Anonymous readers can reach these pages when the account is public, so
  a crawler that walks the tree could otherwise drive real translation
  gateway cost and DB load. Signed-in visitors are keyed by user id so
  many people behind one NAT or CGNAT egress don't share the same ceiling
  with each other; anonymous visitors fall back to a per-IP bucket, which
  is the actual crawler backstop. The 429 response is a themed, localized
  HTML page — browsers should not receive a bare JSON envelope on this
  pipeline.

  Only the HTTP request that mounts a LiveView is rate-limited; LiveView
  events on the WebSocket bypass this. That is currently sufficient
  because every cost-bearing action is guarded by write authorization
  which anonymous visitors never satisfy — if we ever expose an
  anonymous-invokable expensive event, it needs its own bucket inside its
  `handle_event`.

  This module is a preset for `GlossiaWeb.Plugs.RateLimit`: `init/1`
  merges caller options over the base configuration, so a pipeline that
  needs a temporarily higher ceiling for staging or a canary can pass
  `plug BrowseRateLimit, limit: 5_000` without recompiling the module.
  Anything the caller does not override falls back to the defaults below.
  """

  @base [
    key_prefix: "browse",
    scale: 60_000,
    limit: 1_000,
    by: :user,
    format: :html
  ]

  def init(overrides) when is_list(overrides) do
    GlossiaWeb.Plugs.RateLimit.init(Keyword.merge(@base, overrides))
  end

  def call(conn, config) do
    GlossiaWeb.Plugs.RateLimit.call(conn, config)
  end
end
