defmodule GlossiaWeb.Controllers.DocsController do
  use GlossiaWeb.Helpers.Marketing, :controller

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def index(%{request_path: _} = conn, _params) do
    priv_dir = :code.priv_dir(:glossia)
    index_path = Path.join([priv_dir, "static", "docs/index.html"])

    conn |> put_resp_content_type("text/html") |> send_file(200, index_path)
  end
end
