defmodule GlossiaWeb.FeatureController do
  use GlossiaWeb, :controller

  alias Glossia.Features

  def index(conn, _params) do
    pages = Features.all_pages()

    render(conn, :index,
      pages: pages,
      page_title: gettext("Features"),
      page_description:
        gettext(
          "Explore the capabilities that make Glossia the content agent for your codebase. From translation to content revisioning, see how AI-powered workflows fit into your existing tools."
        )
    )
  end

  def show(conn, %{"slug" => slug}) do
    page = Features.get_page_by_slug!(slug)

    render(conn, :show,
      page: page,
      page_title: page.title,
      page_description: page.summary
    )
  end
end
