defmodule GlossiaWeb.Feed do
  @moduledoc false

  import Plug.Conn

  def send(conn, attrs) do
    body = render(attrs, GlossiaWeb.Endpoint.url())

    conn
    |> put_resp_content_type("application/rss+xml")
    |> send_resp(200, body)
  end

  defp render(attrs, base_url) do
    items =
      attrs[:items]
      |> Enum.map_join("\n", &render_item(&1, base_url))

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0">
      <channel>
        <title>#{xml_escape(attrs[:title])}</title>
        <description>#{xml_escape(attrs[:description])}</description>
        <link>#{xml_escape(absolute_url(base_url, attrs[:path]))}</link>
    #{items}
      </channel>
    </rss>
    """
  end

  defp render_item(item, base_url) do
    """
        <item>
          <title>#{xml_escape(item.title)}</title>
          <description>#{xml_escape(item.description)}</description>
          <link>#{xml_escape(absolute_url(base_url, item.path))}</link>
          <guid>#{xml_escape(absolute_url(base_url, item.path))}</guid>
          <pubDate>#{rfc822(item.date)}</pubDate>
        </item>
    """
  end

  defp absolute_url(base_url, path), do: base_url |> URI.merge(path) |> URI.to_string()

  defp rfc822(%Date{} = date) do
    date
    |> DateTime.new!(~T[00:00:00], "Etc/UTC")
    |> Calendar.strftime("%a, %d %b %Y %H:%M:%S GMT")
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
