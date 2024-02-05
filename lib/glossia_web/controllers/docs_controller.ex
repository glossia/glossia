defmodule GlossiaWeb.Controllers.DocsController do
  use GlossiaWeb.Helpers.Docs, :controller
  alias Glossia.Docs.Content

  @spec show(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def show(%{request_path: request_path} = conn, _params) do
    slug = request_path |> String.replace("/docs/", "")
    page = Content.pages() |> Enum.find(fn page -> page.slug == slug end)
    conn |> assign(:navigation, Content.navigation()) |> assign(:page, page) |> render(:show)
  end
end
