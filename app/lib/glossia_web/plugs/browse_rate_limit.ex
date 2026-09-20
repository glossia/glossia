defmodule GlossiaWeb.Plugs.BrowseRateLimit do
  @moduledoc """
  Rate limits HTML browsing of the platform on the pipeline that serves
  unauthenticated visitors — the account, project, translations, session,
  voice, terminology and discussion routes.

  Anonymous readers can reach these pages when the account is public, so a
  crawler that walks the tree could otherwise drive real translation
  gateway and LLM cost. The limit is keyed by client IP (Cloudflare or
  the first X-Forwarded-For hop, falling back to the socket peer) and
  applies to authenticated visitors on the same routes too — the same
  ceiling still leaves plenty of headroom for a human session.

  The 429 response uses `:text` so the browser gets a plain-text body
  instead of the JSON envelope that `Plugs.RateLimit` produces by default
  for API surfaces.
  """

  @config GlossiaWeb.Plugs.RateLimit.init(
            key_prefix: "browse",
            scale: 60_000,
            limit: 1_000,
            by: :ip,
            format: :text
          )

  def init(opts), do: opts

  def call(conn, _opts) do
    GlossiaWeb.Plugs.RateLimit.call(conn, @config)
  end
end
