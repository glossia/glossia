defmodule GlossiaWeb.OpenApiController do
  use GlossiaWeb, :controller

  def show(conn, _params) do
    json(conn, GlossiaWeb.OpenApiSpec.spec())
  end
end
