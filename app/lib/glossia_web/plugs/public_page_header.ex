defmodule GlossiaWeb.Plugs.PublicPageHeader do
  @moduledoc """
  Stamp the `x-glossia-public: 1` response header on every response
  flowing through the `:public` pipeline.

  Cloudflare's rate-limit rules in
  `ops/infra/k8s/workload-platforms/glossia-production/cloudflare` key on
  this header via a `countingExpression`, which lets the edge throttle
  "public page traffic" without a URL allow-list that would need
  updating every time the marketing site adds a section.

  Runs on both the success path and, thanks to `register_before_send/2`,
  on error responses — the header is present regardless of which
  controller runs.
  """

  import Plug.Conn

  @header "x-glossia-public"
  @value "1"

  def init(opts), do: opts

  def call(conn, _opts) do
    register_before_send(conn, &put_resp_header(&1, @header, @value))
  end
end
