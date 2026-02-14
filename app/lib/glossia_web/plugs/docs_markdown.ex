defmodule GlossiaWeb.Plugs.DocsMarkdown do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(%{method: "GET", path_info: ["docs", category, slug_md]} = conn, _opts) do
    case String.split(slug_md, ".") do
      [slug, "md"] ->
        serve_markdown(conn, category, slug)

      _ ->
        conn
    end
  end

  def call(conn, _opts), do: conn

  defp serve_markdown(conn, category, slug) do
    page = Glossia.Docs.get_page!(category, slug)

    case page.markdown do
      nil ->
        conn

      md ->
        conn
        |> put_resp_content_type("text/markdown")
        |> send_resp(200, md)
        |> halt()
    end
  rescue
    Glossia.Docs.NotFoundError -> conn
  end
end
