defmodule GlossiaWeb.SitemapController do
  use GlossiaWeb, :controller

  alias Glossia.Extensions

  def show(conn, _params) do
    base = GlossiaWeb.Endpoint.url()

    urls =
      static_urls(base) ++
        blog_urls(base) ++
        feature_urls(base) ++
        doc_urls(base) ++
        legal_urls(base)

    xml = render_sitemap(urls)

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end

  defp static_urls(base) do
    [
      %{loc: base <> "/"},
      %{loc: base <> "/blog"},
      %{loc: base <> "/features"},
      %{loc: base <> "/changelog"},
      %{loc: base <> "/docs"}
    ]
  end

  defp blog_urls(base) do
    Extensions.site().all_blog_posts()
    |> Enum.map(fn post ->
      %{loc: base <> "/blog/#{post.slug}", lastmod: Date.to_iso8601(post.date)}
    end)
  end

  defp feature_urls(base) do
    Extensions.site().all_feature_pages()
    |> Enum.map(fn page ->
      %{loc: base <> "/features/#{page.slug}"}
    end)
  end

  defp doc_urls(base) do
    doc_pages =
      Extensions.site().all_docs_pages()
      |> Enum.map(fn page ->
        path =
          if page.subcategory do
            "/docs/#{page.category}/#{page.subcategory}/#{page.slug}"
          else
            "/docs/#{page.category}/#{page.slug}"
          end

        %{loc: base <> path}
      end)

    category_pages =
      Extensions.site().all_docs_pages()
      |> Enum.map(& &1.category)
      |> Enum.uniq()
      |> Enum.map(fn category ->
        %{loc: base <> "/docs/#{category}"}
      end)

    synthetic_pages = [
      %{loc: base <> "/docs/reference/apis/rest"},
      %{loc: base <> "/docs/reference/mcp/tools"},
      %{loc: base <> "/docs/reference/mcp/prompts"}
    ]

    category_pages ++ doc_pages ++ synthetic_pages
  end

  defp legal_urls(base) do
    [
      %{loc: base <> "/terms"},
      %{loc: base <> "/privacy"},
      %{loc: base <> "/cookies"}
    ]
  end

  defp render_sitemap(urls) do
    url_entries =
      urls
      |> Enum.map(fn url ->
        lastmod =
          case Map.get(url, :lastmod) do
            nil -> ""
            date -> "    <lastmod>#{date}</lastmod>\n"
          end

        "  <url>\n    <loc>#{xml_escape(url.loc)}</loc>\n#{lastmod}  </url>"
      end)
      |> Enum.join("\n")

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{url_entries}
    </urlset>
    """
  end

  defp xml_escape(string) do
    string
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
