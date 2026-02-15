defmodule GlossiaWeb.PageController do
  use GlossiaWeb, :controller

  alias Glossia.Blog
  alias Glossia.OgImage

  def home(conn, _params) do
    posts = Blog.recent_posts(2)

    og_attrs = %{
      title: "Glossia",
      description: "Content agents for multi-lingual and mono-lingual projects",
      category: "home"
    }

    render(conn, :home,
      posts: posts,
      page_title: gettext("Home"),
      page_description: og_attrs.description,
      og_image_url: OgImage.marketing_url(og_attrs)
    )
  end
end
