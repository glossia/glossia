defmodule GlossiaWeb.ChangelogController do
  use GlossiaWeb, :controller

  alias Glossia.Changelog
  alias Glossia.OgImage

  def index(conn, _params) do
    entries = Changelog.all_entries()

    og_attrs = %{
      title: "Changelog",
      description: "New updates and improvements to Glossia",
      category: "changelog"
    }

    render(conn, :index,
      entries: entries,
      page_title: gettext("Changelog"),
      page_description: og_attrs.description,
      og_image_url: OgImage.marketing_url(og_attrs)
    )
  end

  def feed(conn, _params) do
    entries = Changelog.all_entries()

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, render_feed(entries))
  end

  defp render_feed(entries) do
    base_url = GlossiaWeb.Endpoint.url()

    items =
      Enum.map_join(entries, "\n", fn entry ->
        """
        <item>
          <title><![CDATA[#{entry.title}]]></title>
          <link>#{base_url}/changelog##{entry.slug}</link>
          <guid>#{base_url}/changelog##{entry.slug}</guid>
          <description><![CDATA[#{entry.summary}]]></description>
          <pubDate>#{format_rfc822(entry.date)}</pubDate>
        </item>
        """
      end)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
      <channel>
        <title>Glossia Changelog</title>
        <link>#{base_url}/changelog</link>
        <description>New updates and improvements to Glossia</description>
        <language>en</language>
        <atom:link href="#{base_url}/changelog/feed.xml" rel="self" type="application/rss+xml"/>
        #{items}
      </channel>
    </rss>
    """
  end

  defp format_rfc822(date) do
    Calendar.strftime(date, "%a, %d %b %Y 00:00:00 +0000")
  end
end
