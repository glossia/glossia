defmodule GlossiaWeb.BlogController do
  use GlossiaWeb, :controller

  alias Glossia.Extensions
  alias Glossia.OgImage

  def index(conn, _params) do
    posts = Extensions.marketing().all_blog_posts()

    og_attrs = %{
      title: "Blog",
      description: "Updates from the Glossia team",
      category: "blog"
    }

    render(conn, :index,
      posts: posts,
      page_title: gettext("Blog"),
      page_description: og_attrs.description,
      og_image_url: OgImage.marketing_url(og_attrs)
    )
  end

  def show(conn, %{"slug" => slug}) do
    post = Extensions.marketing().blog_post_by_slug!(slug)

    og_attrs = %{
      title: post.title,
      description: post.summary,
      category: "blog",
      author_name: post.author.name,
      author_avatar: post.author.avatar
    }

    conn
    |> assign(:author, post.author)
    |> render(:show,
      post: post,
      page_title: post.title,
      page_description: post.summary,
      og_image_url: OgImage.marketing_url(og_attrs)
    )
  end

  def feed(conn, _params) do
    posts = Extensions.marketing().all_blog_posts()

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, render_feed(conn, posts))
  end

  defp render_feed(_conn, posts) do
    base_url = GlossiaWeb.Endpoint.url()

    items =
      Enum.map_join(posts, "\n", fn post ->
        """
        <item>
          <title><![CDATA[#{post.title}]]></title>
          <link>#{base_url}/blog/#{post.slug}</link>
          <guid>#{base_url}/blog/#{post.slug}</guid>
          <description><![CDATA[#{post.summary}]]></description>
          <pubDate>#{format_rfc822(post.date)}</pubDate>
        </item>
        """
      end)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
      <channel>
        <title>Glossia Blog</title>
        <link>#{base_url}/blog</link>
        <description>Updates from the Glossia team</description>
        <language>en</language>
        <atom:link href="#{base_url}/blog/feed.xml" rel="self" type="application/rss+xml"/>
        #{items}
      </channel>
    </rss>
    """
  end

  defp format_rfc822(date) do
    Calendar.strftime(date, "%a, %d %b %Y 00:00:00 +0000")
  end
end
