defmodule GlossiaWeb.OpenApiController do
  use GlossiaWeb, :controller

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "openapi_spec",
    scale: :timer.minutes(1),
    limit: 120,
    by: :ip

  def show(conn, _params) do
    json(conn, GlossiaWeb.OpenApiSpec.spec())
  end
end
