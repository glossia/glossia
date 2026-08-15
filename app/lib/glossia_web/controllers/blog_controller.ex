defmodule GlossiaWeb.BlogController do
  use GlossiaWeb, :controller

  alias Glossia.Blog
  alias GlossiaWeb.Feed

  def index(conn, _params) do
    render(conn, :index,
      posts: Blog.all_posts(conn.assigns.locale),
      page_title: gettext("Blog"),
      page_description: gettext("Notes on localization, language systems, and agentic workflows.")
    )
  end

  def show(conn, %{"slug" => slug}) do
    post = Blog.get_post!(slug, conn.assigns.locale)

    render(conn, :show,
      post: post,
      author: post.author,
      page_title: post.title,
      page_description: post.summary,
      og_image_url:
        Glossia.OgImage.marketing_url(%{
          category: "blog",
          title: post.title,
          summary: post.summary
        })
    )
  end

  def feed(conn, _params) do
    locale = conn.assigns.locale

    Feed.send(conn,
      title: "Glossia Blog",
      description: gettext("Notes on localization, language systems, and agentic workflows."),
      path: locale_path(~p"/blog"),
      items:
        Enum.map(Blog.all_posts(locale), fn post ->
          %{
            title: post.title,
            description: post.summary,
            path: locale_path(~p"/blog/#{post.slug}"),
            date: post.date
          }
        end)
    )
  end
end
