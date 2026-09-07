defmodule GlossiaWeb.Plugs.McpRateLimit do
  @moduledoc """
  Rate limits authenticated MCP requests.
  """

  @config GlossiaWeb.Plugs.RateLimit.init(
            key_prefix: "mcp",
            scale: 60_000,
            limit: 240,
            by: :user
          )

  def init(opts), do: opts

  def call(conn, _opts) do
    GlossiaWeb.Plugs.RateLimit.call(conn, @config)
  end
end
