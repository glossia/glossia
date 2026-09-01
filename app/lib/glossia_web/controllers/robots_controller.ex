defmodule GlossiaWeb.RobotsController do
  use GlossiaWeb, :controller

  def show(conn, _params) do
    sitemap_url = GlossiaWeb.Endpoint.url() |> URI.merge("/sitemap.xml") |> URI.to_string()

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "User-agent: *\nAllow: /\nSitemap: #{sitemap_url}\n")
  end
end
