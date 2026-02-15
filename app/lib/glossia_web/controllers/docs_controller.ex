defmodule GlossiaWeb.DocsController do
  use GlossiaWeb, :controller

  alias Glossia.Docs
  alias Glossia.OgImage

  def index(conn, _params) do
    categories = Docs.categories()

    og_attrs = %{
      title: "Documentation",
      description: "Glossia documentation and guides",
      category: "docs"
    }

    render(conn, :index,
      categories: categories,
      page_title: gettext("Documentation"),
      og_image_url: OgImage.marketing_url(og_attrs)
    )
  end

  def category(conn, %{"category" => category}) do
    categories = Docs.categories()

    category_meta =
      Map.get(categories, category) ||
        raise Glossia.Docs.NotFoundError, "category #{category} not found"

    pages = Docs.pages_by_category(category)
    subcategories = Docs.subcategories_for(category)

    items =
      (Enum.map(pages, fn p ->
         %{
           title: p.title,
           summary: p.summary,
           href: ~p"/docs/#{p.category}/#{p.slug}",
           order: p.order
         }
       end) ++
         Enum.map(subcategories, fn sc ->
           %{
             title: sc.title,
             summary: sc.summary,
             href: ~p"/docs/#{category}/#{sc.key}",
             order: sc.order
           }
         end))
      |> Enum.sort_by(& &1.order)

    sidebar = build_sidebar(category)

    render(conn, :category,
      category_key: category,
      category_meta: category_meta,
      items: items,
      categories: categories,
      sidebar: sidebar,
      page_title: category_meta.title
    )
  end

  def show(conn, %{"category" => category, "slug" => slug}) do
    subcategories = Docs.subcategories_for(category)

    if Enum.any?(subcategories, &(&1.key == slug)) do
      render_subcategory(conn, category, slug)
    else
      page = Docs.get_page!(category, slug)
      categories = Docs.categories()
      sidebar = build_sidebar(category)

      og_attrs = %{title: page.title, description: page.summary || "", category: "docs"}

      render(conn, :show,
        page: page,
        categories: categories,
        sidebar: sidebar,
        current_category: category,
        current_slug: slug,
        page_title: page.title,
        og_image_url: OgImage.marketing_url(og_attrs)
      )
    end
  end

  def subcategory_page(conn, %{
        "category" => "reference",
        "subcategory" => "apis",
        "slug" => "rest"
      }) do
    subcategory_meta = Docs.subcategory!("reference", "apis")
    sidebar = build_sidebar("reference")

    render(conn, :api_reference,
      categories: Docs.categories(),
      sidebar: sidebar,
      current_category: "reference",
      current_subcategory: "apis",
      current_subcategory_meta: subcategory_meta,
      page_title: gettext("REST")
    )
  end

  def subcategory_page(conn, %{
        "category" => category,
        "subcategory" => subcategory,
        "slug" => slug
      }) do
    page = Docs.get_subcategory_page!(category, subcategory, slug)
    subcategory_meta = Docs.subcategory!(category, subcategory)
    categories = Docs.categories()
    sidebar = build_sidebar(category)

    render(conn, :show,
      page: page,
      categories: categories,
      sidebar: sidebar,
      current_category: category,
      current_subcategory: subcategory,
      current_subcategory_meta: subcategory_meta,
      current_slug: slug,
      page_title: page.title
    )
  end

  def search_index(conn, _params) do
    json(conn, Docs.search_index())
  end

  defp render_subcategory(conn, category, subcategory_key) do
    subcategory_meta = Docs.subcategory!(category, subcategory_key)
    category_meta = Map.fetch!(Docs.categories(), category)
    pages = Docs.pages_by_subcategory(category, subcategory_key)
    sidebar = build_sidebar(category)

    render(conn, :subcategory,
      category_key: category,
      category_meta: category_meta,
      subcategory_key: subcategory_key,
      subcategory_meta: subcategory_meta,
      pages: pages,
      categories: Docs.categories(),
      sidebar: sidebar,
      page_title: subcategory_meta.title
    )
  end

  defp build_sidebar(current_category) do
    Docs.categories()
    |> Enum.map(fn {key, meta} ->
      pages = Docs.pages_by_category(key)
      subcategories = Docs.subcategories_for(key)

      subcategory_items =
        Enum.map(subcategories, fn sc ->
          %{
            key: sc.key,
            title: sc.title,
            pages: Docs.pages_by_subcategory(key, sc.key)
          }
        end)

      %{
        key: key,
        title: meta.title,
        pages: pages,
        subcategories: subcategory_items,
        active: key == current_category
      }
    end)
    |> Enum.sort_by(fn section ->
      Enum.find_index(~w(tutorials how-to reference explanation), &(&1 == section.key)) || 99
    end)
  end
end
