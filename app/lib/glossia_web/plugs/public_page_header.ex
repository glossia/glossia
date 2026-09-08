defmodule GlossiaWeb.Plugs.PublicPageHeader do
  @moduledoc """
  Stamp the `x-glossia-public: 1` response header on every response
  flowing through the `:public` pipeline.

  Historically this fed a Cloudflare rate-limit rule that keyed on the
  header via `countingExpression`; the current rules in
  `github.com/glossia/infra` use path-exclusion match instead (basic
  plan doesn't allow `countingExpression`), so the header is
  informational today. Kept because it costs nothing to stamp and
  gives the edge an easy hook if we ever bump the Cloudflare plan.

  Runs on both the success path and, thanks to `register_before_send/2`,
  on error responses.
  """

  import Plug.Conn

  @header "x-glossia-public"
  @value "1"

  def init(opts), do: opts

  def call(conn, _opts) do
    register_before_send(conn, &put_resp_header(&1, @header, @value))
  end
end
