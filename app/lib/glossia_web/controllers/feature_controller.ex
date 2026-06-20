defmodule GlossiaWeb.FeatureController do
  use GlossiaWeb, :controller

  alias Glossia.Features

  def index(conn, _params) do
    render(conn, :index,
      pages: Features.all_pages(),
      page_title: gettext("Features"),
      page_description:
        gettext("Explore Glossia's language memory, localization, API, and MCP capabilities.")
    )
  end

  def show(conn, %{"slug" => slug}) do
    page = Features.get_page!(slug)

    render(conn, :show,
      page: page,
      page_title: page.title,
      page_description: page.summary,
      og_image_url:
        Glossia.OgImage.marketing_url(%{
          category: "features",
          title: page.title,
          summary: page.summary
        })
    )
  end
end
