defmodule GlossiaWeb.Controllers.DocsController do
  use GlossiaWeb.Helpers.Docs, :controller
  alias Glossia.Docs.Content

  @spec show(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def show(conn, _params) do
    conn |> assign(:navigation, Content.navigation()) |> render(:show)
  end
end
