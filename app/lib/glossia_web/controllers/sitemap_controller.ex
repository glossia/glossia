defmodule GlossiaWeb.SitemapController do
  use GlossiaWeb, :controller

  alias Glossia.{Blog, Changelog, Docs, Features, Legal}

  def show(conn, _params) do
    base_url = GlossiaWeb.Endpoint.url()

    urls =
      [
        %{path: "/"},
        %{path: "/blog"},
        %{path: "/features"},
        %{path: "/changelog"},
        %{path: "/docs"}
      ] ++
        Enum.map(Blog.all_posts(), &%{path: "/blog/#{&1.slug}", lastmod: &1.date}) ++
        Enum.map(Features.all_pages(), &%{path: "/features/#{&1.slug}"}) ++
        Enum.map(Changelog.all_entries(), &%{path: "/changelog##{&1.slug}", lastmod: &1.date}) ++
        Enum.map(Docs.all_pages(), &%{path: Docs.path_for(&1)}) ++
        Enum.map(~w(terms privacy cookies), fn document ->
          %{path: "/#{document}", lastmod: Legal.latest_version!(document).date}
        end)

    xml = render_sitemap(base_url, urls)

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end

  defp render_sitemap(base_url, urls) do
    entries =
      Enum.map_join(urls, "\n", fn url ->
        loc = xml_escape(base_url <> url.path)

        lastmod =
          if url[:lastmod],
            do: "\n    <lastmod>#{Date.to_iso8601(url.lastmod)}</lastmod>",
            else: ""

        "  <url>\n    <loc>#{loc}</loc>#{lastmod}\n  </url>"
      end)

    ~s(<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
#{entries}
</urlset>
)
  end

  defp xml_escape(value) do
    value
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
