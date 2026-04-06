defmodule GlossiaWeb.PageController do
  use GlossiaWeb, :controller

  alias Glossia.Extensions
  alias Glossia.OgImage

  def home(conn, _params) do
    posts = Extensions.site().recent_blog_posts(3)

    og_attrs = %{
      title: "Glossia",
      description:
        "Glossia captures your voice, terminology, and tone in one place so linguists and teams can shape how your organization speaks across every language and surface.",
      category: "home"
    }

    render(conn, :home,
      posts: posts,
      page_title: nil,
      page_description: og_attrs.description,
      og_image_url: OgImage.marketing_url(og_attrs)
    )
  end
end
