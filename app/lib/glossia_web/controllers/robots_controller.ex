defmodule GlossiaWeb.RobotsController do
  use GlossiaWeb, :controller

  alias Glossia.{I18n, PublicContent}
  alias GlossiaWeb.MarkdownResponse

  def show(conn, _params) do
    # Default-deny application URLs. Opt in only the finite published inventory,
    # not /:handle dashboards or arbitrary locale-looking prefixes.
    paths =
      Enum.flat_map(I18n.locales(), fn locale ->
        content_paths =
          Enum.flat_map(PublicContent.documents(locale), fn {path, _markdown} ->
            path = I18n.localize_path(locale, path)

            if PublicContent.markdown_only?(path),
              do: [PublicContent.markdown_path(path)],
              else: [path, PublicContent.markdown_path(path)]
          end)

        feed_paths =
          Enum.map([~p"/blog/feed.xml", ~p"/changelog/feed.xml"], &I18n.localize_path(locale, &1))

        content_paths ++ feed_paths
      end)

    paths = paths ++ [~p"/robots.txt", ~p"/llms.txt", ~p"/llms-full.txt", ~p"/sitemap.xml"]
    allows = paths |> Enum.uniq() |> Enum.sort() |> Enum.map_join("\n", &"Allow: #{&1}$")
    sitemap_url = GlossiaWeb.Endpoint.url() |> URI.merge(~p"/sitemap.xml") |> URI.to_string()

    # These are crawler-rule prefixes, not content URLs. Allow rendering assets
    # and marketing previews without opening database-backed /og/app/ images.
    resource_allows =
      Enum.join(
        [
          "Allow: /assets/",
          "Allow: /fonts/",
          "Allow: /images/",
          "Allow: /favicon.ico$",
          "Allow: /og/marketing/"
        ],
        "\n"
      )

    content =
      "User-agent: *\nDisallow: /\n#{resource_allows}\n#{allows}\nSitemap: #{sitemap_url}\n"

    MarkdownResponse.send(conn, content, content_type: "text/plain", robots: "noindex, follow")
  end
end
