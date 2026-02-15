defmodule GlossiaWeb.FeatureController do
  use GlossiaWeb, :controller

  alias Glossia.Features
  alias Glossia.OgImage

  def index(conn, _params) do
    pages = Features.all_pages()

    description =
      gettext(
        "Explore the capabilities that make Glossia the content agent for your codebase. From localization to content revisioning, see how AI-powered workflows fit into your existing tools."
      )

    og_attrs = %{title: "Features", description: description, category: "features"}

    render(conn, :index,
      pages: pages,
      page_title: gettext("Features"),
      page_description: description,
      og_image_url: OgImage.marketing_url(og_attrs)
    )
  end

  def show(conn, %{"slug" => slug}) do
    page = Features.get_page_by_slug!(slug)

    og_attrs = %{title: page.title, description: page.summary, category: "feature"}

    render(conn, :show,
      page: page,
      page_title: page.title,
      page_description: page.summary,
      og_image_url: OgImage.marketing_url(og_attrs)
    )
  end
end
