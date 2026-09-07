defmodule GlossiaWeb.SitemapController do
  use GlossiaWeb, :controller

  alias Glossia.{Blog, Changelog, Docs, Features, I18n, Legal}

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
        Enum.map(
          Changelog.all_entries(),
          &%{path: URI.to_string(%URI{path: "/changelog", fragment: &1.slug}), lastmod: &1.date}
        ) ++
        Enum.map(Docs.all_pages(), &%{path: Docs.path_for(&1)}) ++
        Enum.map(~w(terms privacy cookies), fn document ->
          %{path: "/#{document}", lastmod: Legal.latest_version!(document).date}
        end)

    xml = render_sitemap(base_url, urls)

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end

  # Every page is listed once per locale, and each entry carries the full set of
  # alternates so search engines can tie the translations together.
  defp render_sitemap(base_url, urls) do
    entries =
      Enum.map_join(urls, "\n", fn url ->
        alternates = alternates(base_url, url.path)

        Enum.map_join(I18n.locales(), "\n", fn locale ->
          loc = xml_escape(absolute_url(base_url, I18n.localize_path(locale, url.path)))

          lastmod =
            if url[:lastmod],
              do: "\n    <lastmod>#{Date.to_iso8601(url.lastmod)}</lastmod>",
              else: ""

          "  <url>\n    <loc>#{loc}</loc>#{lastmod}\n#{alternates}  </url>"
        end)
      end)

    ~s(<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
#{entries}
</urlset>
)
  end

  defp alternates(base_url, path) do
    hreflangs = I18n.locales() ++ ["x-default"]

    Enum.map_join(hreflangs, "", fn hreflang ->
      locale = if hreflang == "x-default", do: I18n.default_locale(), else: hreflang
      href = xml_escape(absolute_url(base_url, I18n.localize_path(locale, path)))

      ~s(    <xhtml:link rel="alternate" hreflang="#{hreflang}" href="#{href}" />\n)
    end)
  end

  defp absolute_url(base_url, path), do: base_url |> URI.merge(path) |> URI.to_string()

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
