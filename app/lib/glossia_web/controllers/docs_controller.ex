defmodule GlossiaWeb.DocsController do
  use GlossiaWeb, :controller

  alias Glossia.Docs

  def index(conn, _params) do
    categories = Docs.categories()
    render(conn, :index, categories: categories)
  end

  def category(conn, %{"category" => category}) do
    categories = Docs.categories()

    category_meta =
      Map.get(categories, category) ||
        raise Glossia.Docs.NotFoundError, "category #{category} not found"

    pages = Docs.pages_by_category(category)
    sidebar = build_sidebar(category)

    render(conn, :category,
      category_key: category,
      category_meta: category_meta,
      pages: pages,
      categories: categories,
      sidebar: sidebar
    )
  end

  def show(conn, %{"category" => "reference", "slug" => "api"}) do
    sidebar = build_sidebar("reference")

    render(conn, :api_reference,
      categories: Docs.categories(),
      sidebar: sidebar,
      current_category: "reference",
      page_title: gettext("API Reference")
    )
  end

  def show(conn, %{"category" => category, "slug" => slug}) do
    page = Docs.get_page!(category, slug)
    categories = Docs.categories()
    sidebar = build_sidebar(category)

    render(conn, :show,
      page: page,
      categories: categories,
      sidebar: sidebar,
      current_category: category,
      current_slug: slug
    )
  end

  def search_index(conn, _params) do
    json(conn, Docs.search_index())
  end

  defp build_sidebar(current_category) do
    Docs.categories()
    |> Enum.map(fn {key, meta} ->
      pages = Docs.pages_by_category(key)
      %{key: key, title: meta.title, pages: pages, active: key == current_category}
    end)
    |> Enum.sort_by(fn section ->
      Enum.find_index(~w(tutorials how-to reference explanation), &(&1 == section.key)) || 99
    end)
  end
end
