defmodule GlossiaWeb.Plugs.ApiRateLimit do
  @moduledoc """
  Rate limits authenticated REST API requests.
  """

  @config GlossiaWeb.Plugs.RateLimit.init(
            key_prefix: "api",
            scale: 60_000,
            limit: 120,
            by: :user
          )

  def init(opts), do: opts

  def call(conn, _opts) do
    GlossiaWeb.Plugs.RateLimit.call(conn, @config)
  end
end
