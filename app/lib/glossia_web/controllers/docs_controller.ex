defmodule GlossiaWeb.DocsController do
  use GlossiaWeb, :controller

  alias Glossia.Docs

  @category_order ~w(tutorials how-to reference explanation)

  plug :put_layout, html: {GlossiaWeb.Layouts, :docs}
  plug :assign_docs_navigation

  def index(conn, _params) do
    categories = Docs.sorted_categories(conn.assigns.locale)

    render(conn, :index,
      categories: categories,
      docs_current_category: nil,
      docs_current_subcategory: nil,
      docs_current_slug: nil,
      docs_headings: category_headings(categories),
      page_title: gettext("Documentation"),
      page_description: gettext("Learn how to use Glossia to localize and improve your content.")
    )
  end

  def category(conn, %{"category" => category}) do
    items = Docs.category_items(category, conn.assigns.locale)

    render(conn, :category,
      category_meta: Docs.category_meta!(category),
      items: items,
      docs_current_category: category,
      docs_current_subcategory: nil,
      docs_current_slug: nil,
      docs_headings: item_headings(items),
      page_title: Docs.category_meta!(category).title,
      page_description: Docs.category_meta!(category).summary
    )
  end

  def section(conn, %{"category" => category, "section" => section}) do
    cond do
      markdown_slug?(section) ->
        page = Docs.get_page!(category, nil, strip_markdown_suffix(section), conn.assigns.locale)
        send_markdown(conn, page)

      Docs.subcategory?(category, section) ->
        render_subcategory(conn, category, section)

      true ->
        page = Docs.get_page!(category, nil, section, conn.assigns.locale)
        render_page(conn, page, category, nil)
    end
  end

  def subcategory(conn, %{"category" => category, "subcategory" => subcategory}) do
    render_subcategory(conn, category, subcategory)
  end

  defp render_subcategory(conn, category, subcategory) do
    pages = Docs.subcategory_pages(category, subcategory, conn.assigns.locale)

    render(conn, :subcategory,
      category_key: category,
      category_meta: Docs.category_meta!(category),
      subcategory_key: subcategory,
      subcategory_meta: Docs.subcategory_meta!(category, subcategory),
      pages: pages,
      docs_current_category: category,
      docs_current_subcategory: subcategory,
      docs_current_slug: nil,
      docs_headings: page_headings(pages),
      page_title: Docs.subcategory_meta!(category, subcategory).title,
      page_description: Docs.subcategory_meta!(category, subcategory).summary
    )
  end

  def show(conn, %{"category" => category, "subcategory" => subcategory, "slug" => slug}) do
    if markdown_slug?(slug) do
      page =
        Docs.get_page!(category, subcategory, strip_markdown_suffix(slug), conn.assigns.locale)

      send_markdown(conn, page)
    else
      page = Docs.get_page!(category, subcategory, slug, conn.assigns.locale)

      render_page(conn, page, category, subcategory)
    end
  end

  def show(conn, %{"category" => category, "slug" => slug}) do
    if markdown_slug?(slug) do
      page = Docs.get_page!(category, nil, strip_markdown_suffix(slug), conn.assigns.locale)

      send_markdown(conn, page)
    else
      page = Docs.get_page!(category, nil, slug, conn.assigns.locale)

      render_page(conn, page, category, nil)
    end
  end

  def search_index(conn, params) do
    locale = Glossia.I18n.normalize(params["locale"]) || Glossia.I18n.default_locale()

    json(conn, Docs.search_index(locale))
  end

  defp markdown_slug?(slug) do
    String.ends_with?(slug, ".md")
  end

  defp strip_markdown_suffix(slug) do
    String.replace_suffix(slug, ".md", "")
  end

  defp render_page(conn, %{kind: :api_reference} = page, category, subcategory) do
    render(conn, :api_reference,
      page: page,
      categories: Docs.categories(),
      current_category: category,
      current_subcategory: subcategory,
      current_subcategory_meta: Docs.subcategory_meta!("reference", "apis"),
      docs_current_category: category,
      docs_current_subcategory: subcategory,
      docs_current_slug: page.slug,
      docs_headings: [],
      page_title: page.title,
      page_description: page.summary
    )
  end

  defp render_page(conn, page, category, subcategory) do
    render(conn, :show,
      page: page,
      categories: Docs.categories(),
      current_category: category,
      current_subcategory: subcategory,
      current_subcategory_meta: subcategory && Docs.subcategory_meta!(category, subcategory),
      current_slug: page.slug,
      docs_current_category: category,
      docs_current_subcategory: subcategory,
      docs_current_slug: page.slug,
      docs_headings: page.toc,
      docs_markdown: page.raw_markdown,
      docs_markdown_path: locale_path(markdown_path(category, subcategory, page.slug)),
      page_title: page.title,
      page_description: page.summary
    )
  end

  defp assign_docs_navigation(conn, _opts) do
    locale = conn.assigns[:locale] || Glossia.I18n.default_locale()

    assign(conn, :docs_navigation, Docs.navigation(locale))
  end

  defp category_headings(categories) do
    categories
    |> Map.take(@category_order)
    |> Enum.sort_by(fn {key, _category} -> Enum.find_index(@category_order, &(&1 == key)) end)
    |> Enum.map(fn {key, category} ->
      %{id: "docs-category-#{key}", text: category.title, level: 2}
    end)
  end

  defp item_headings(items) do
    Enum.map(items, &%{id: &1.id, text: &1.title, level: 2})
  end

  defp page_headings(pages) do
    Enum.map(pages, &%{id: &1.id, text: &1.title, level: 2})
  end

  defp markdown_path(category, nil, slug), do: ~p"/docs/#{category}/#{slug <> ".md"}"

  defp markdown_path(category, subcategory, slug),
    do: ~p"/docs/#{category}/#{subcategory}/#{slug <> ".md"}"

  defp send_markdown(conn, %{markdown: true, raw_markdown: raw_markdown})
       when is_binary(raw_markdown) do
    conn
    |> put_resp_content_type("text/markdown")
    |> send_resp(200, raw_markdown <> "\n")
  end

  defp send_markdown(_conn, page) do
    raise Glossia.Docs.NotFoundError, "markdown not available for #{page.id}"
  end
end
