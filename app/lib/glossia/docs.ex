defmodule Glossia.Docs.Page do
  @moduledoc false

  @enforce_keys [:id, :slug, :title, :summary, :category, :order, :body, :toc]
  defstruct [
    :id,
    :slug,
    :title,
    :summary,
    :category,
    :subcategory,
    :section,
    :order,
    :body,
    :toc,
    :raw_markdown,
    :markdown,
    :kind,
    edition: "community",
    markdown_only: false
  ]

  def build(filename, attrs, body) do
    {category, subcategory, slug, id} = path_parts(filename)
    {body, toc} = Glossia.MarketingMarkdown.process(body, toc: true)

    attrs
    # Routing identifiers come from the source-relative path. Older translated
    # frontmatter may contain localized category names or slugs.
    |> Map.put(:category, category)
    |> Map.put(:subcategory, subcategory)
    |> Map.put(:slug, slug)
    |> Map.put_new(:kind, :doc)
    |> Map.merge(%{
      id: id,
      body: body,
      toc: toc,
      raw_markdown: Glossia.MarketingMarkdown.raw_markdown(filename),
      markdown: true
    })
    |> then(&struct!(__MODULE__, &1))
  end

  defp path_parts(filename) do
    parts =
      filename
      |> Path.rootname()
      |> Path.split()
      |> Enum.drop_while(&(&1 != "docs"))
      |> Enum.drop(1)

    category = List.first(parts)
    slug = List.last(parts)
    subcategory = if length(parts) > 2, do: Enum.at(parts, 1)
    id = Enum.join(parts, "/")

    {category, subcategory, slug, id}
  end
end

defmodule Glossia.Docs do
  @moduledoc false

  use GlossiaWeb, :verified_routes

  use Gettext, backend: GlossiaWeb.Gettext

  alias Glossia.Docs.Page

  @category_order ~w(tutorials how-to reference explanation)

  @categories %{
    "tutorials" => %{
      key: "tutorials",
      title: "Tutorials",
      summary: "Step-by-step lessons to get started with Glossia.",
      icon: "book"
    },
    "how-to" => %{
      key: "how-to",
      title: "How-to guides",
      summary: "Practical directions for specific tasks.",
      icon: "category"
    },
    "reference" => %{
      key: "reference",
      title: "Reference",
      summary: "Technical descriptions of configuration, CLI, and APIs.",
      icon: "file_text"
    },
    "explanation" => %{
      key: "explanation",
      title: "Explanation",
      summary: "Background, design decisions, and concepts.",
      icon: "bulb"
    }
  }

  # Sidebar groups inside a category. A page opts in with `section:` in its
  # frontmatter; pages without one are listed first, without a heading.
  @section_order ~w(translation platform analytics ecosystems)

  @sections %{
    "translation" => %{key: "translation", title: "Translation", icon: "language"},
    "platform" => %{key: "platform", title: "Platform", icon: "users"},
    "analytics" => %{key: "analytics", title: "Analytics", icon: "chart_column"},
    "ecosystems" => %{key: "ecosystems", title: "Ecosystems", icon: "devices_code"}
  }

  @subcategories %{
    "reference/cli" => %{
      category: "reference",
      key: "cli",
      title: "CLI",
      summary: "Command-line tool documentation and release history.",
      section: "platform",
      order: 2
    },
    "reference/apis" => %{
      category: "reference",
      key: "apis",
      title: "APIs",
      summary: "Authentication and REST interfaces.",
      section: "platform",
      order: 3
    },
    "reference/mcp" => %{
      category: "reference",
      key: "mcp",
      title: "MCP",
      summary: "Model Context Protocol server, tools, and prompts.",
      section: "platform",
      order: 4
    }
  }

  use Glossia.ContentPublisher,
    build: Page,
    from: Application.app_dir(:glossia, "priv/docs/**/*.md"),
    i18n: "docs",
    as: :content_pages,
    html_converter: Glossia.Markdown.Publisher

  @content_pages Enum.sort_by(@content_pages, & &1.order)

  # Translations inherit navigation and publication metadata from English so
  # missing or localized frontmatter cannot regroup or expose hidden pages.
  @english_metadata Map.new(
                      @content_pages,
                      &{&1.id, Map.take(&1, [:section, :markdown_only, :edition])}
                    )

  @content_pages_by_locale Map.new(@content_pages_by_locale, fn {locale, pages} ->
                             {locale,
                              pages
                              |> Enum.map(&struct!(&1, Map.fetch!(@english_metadata, &1.id)))
                              |> Enum.sort_by(& &1.order)}
                           end)

  @synthetic_pages [
    %Page{
      id: "reference/apis/rest",
      title: "REST",
      summary: "Interactive reference for OAuth and discovery endpoints.",
      category: "reference",
      subcategory: "apis",
      order: 2,
      slug: "rest",
      kind: :api_reference,
      body: "",
      toc: [],
      markdown: false
    },
    %Page{
      id: "reference/mcp/tools",
      title: "Tools",
      summary: "Available MCP tools and their parameters.",
      category: "reference",
      subcategory: "mcp",
      order: 2,
      slug: "tools",
      kind: :doc,
      body:
        "<p>The tool inventory is maintained by the running Glossia MCP server. Connect an MCP client to <code>/mcp</code> to inspect the current tools and schemas.</p>",
      toc: [],
      raw_markdown:
        "The tool inventory is maintained by the running Glossia MCP server. Connect an MCP client to `/mcp` to inspect the current tools and schemas.",
      markdown: true
    },
    %Page{
      id: "reference/mcp/prompts",
      title: "Prompts",
      summary: "Available MCP prompt templates.",
      category: "reference",
      subcategory: "mcp",
      order: 3,
      slug: "prompts",
      kind: :doc,
      body:
        "<p>Prompt definitions are source-of-truth data in the Glossia application runtime.</p>",
      toc: [],
      raw_markdown:
        "Prompt definitions are source-of-truth data in the Glossia application runtime.",
      markdown: true
    },
    %Page{
      id: "reference/api",
      title: "API reference",
      summary: "Interactive reference for OAuth and discovery endpoints.",
      category: "reference",
      order: 99,
      slug: "api",
      kind: :api_reference,
      body: "",
      toc: [],
      markdown: false
    }
  ]

  @pages @content_pages ++ @synthetic_pages

  @pages_by_locale Map.new(@content_pages_by_locale, fn {locale, pages} ->
                     {locale, pages ++ @synthetic_pages}
                   end)

  def categories do
    Map.new(@categories, fn {key, meta} -> {key, translate_meta(meta)} end)
  end

  def sorted_categories(locale \\ Glossia.I18n.default_locale()) do
    @category_order
    |> Enum.map(&{&1, category_meta!(&1)})
    |> Enum.filter(fn {category, _meta} -> category_items(category, locale) != [] end)
    |> Map.new()
  end

  def category_meta!(category) do
    case Map.fetch(@categories, category) do
      {:ok, meta} -> translate_meta(meta)
      :error -> raise Glossia.Docs.NotFoundError, "doc category not found: #{category}"
    end
  end

  def subcategory_meta!(category, subcategory) do
    case Map.fetch(@subcategories, "#{category}/#{subcategory}") do
      {:ok, meta} ->
        translate_meta(meta)

      :error ->
        raise Glossia.Docs.NotFoundError,
              "doc subcategory not found: #{category}/#{subcategory}"
    end
  end

  def subcategory?(category, subcategory) do
    Map.has_key?(@subcategories, "#{category}/#{subcategory}")
  end

  def category_items(category, locale \\ Glossia.I18n.default_locale()) do
    icon = category_meta!(category).icon

    page_items =
      locale
      |> pages()
      |> Enum.filter(
        &(&1.category == category and is_nil(&1.subcategory) and &1.id != "reference/api")
      )
      |> Enum.map(
        &%{
          id: &1.id,
          title: &1.title,
          summary: &1.summary,
          href: Glossia.I18n.localize_path(locale, path_for(&1)),
          icon: icon,
          order: &1.order
        }
      )

    subcategory_items =
      @subcategories
      |> Map.values()
      |> Enum.filter(
        &(&1.category == category and subcategory_pages(category, &1.key, locale) != [])
      )
      |> Enum.map(fn subcategory ->
        meta = translate_meta(subcategory)

        %{
          id: "#{category}/#{meta.key}",
          title: meta.title,
          summary: meta.summary,
          href: Glossia.I18n.localize_path(locale, "/docs/#{category}/#{meta.key}"),
          icon: icon,
          order: meta.order
        }
      end)

    Enum.sort_by(page_items ++ subcategory_items, & &1.order)
  end

  def subcategory_pages(category, subcategory, locale \\ Glossia.I18n.default_locale()) do
    locale
    |> pages()
    |> Enum.filter(&(&1.category == category and &1.subcategory == subcategory))
    |> Enum.sort_by(& &1.order)
  end

  def all_pages(locale \\ Glossia.I18n.default_locale()) do
    locale |> pages() |> Enum.reject(&(&1.id == "reference/api"))
  end

  def navigation(locale \\ Glossia.I18n.default_locale()) do
    @category_order
    |> Enum.map(fn category ->
      meta = category_meta!(category)

      direct_pages =
        locale
        |> pages()
        |> Enum.filter(
          &(&1.category == category and is_nil(&1.subcategory) and &1.id != "reference/api")
        )
        |> Enum.sort_by(& &1.order)

      subcategories =
        @subcategories
        |> Map.values()
        |> Enum.filter(&(&1.category == category))
        |> Enum.map(fn subcategory ->
          %{
            key: subcategory.key,
            title: translate_meta(subcategory).title,
            section: subcategory[:section],
            pages: subcategory_pages(category, subcategory.key, locale)
          }
        end)
        |> Enum.reject(&(&1.pages == []))
        |> Enum.sort_by(fn subcategory -> subcategory_meta!(category, subcategory.key).order end)

      %{
        key: category,
        title: meta.title,
        sections: navigation_sections(direct_pages, subcategories)
      }
    end)
    |> Enum.reject(&(&1.sections == []))
  end

  # Groups a category's pages and subcategories by their `section`. Unsectioned
  # entries come first with a nil title; unknown section keys are treated as
  # unsectioned so a typo in frontmatter never hides a page.
  defp navigation_sections(pages, subcategories) do
    [nil | @section_order]
    |> Enum.map(fn key ->
      %{
        section: key && translate_section(Map.fetch!(@sections, key)),
        pages: Enum.filter(pages, &(section_key(&1.section) == key)),
        subcategories: Enum.filter(subcategories, &(section_key(&1.section) == key))
      }
    end)
    |> Enum.reject(&(&1.pages == [] and &1.subcategories == []))
    |> Enum.map(fn group ->
      %{
        key: group.section && group.section.key,
        title: group.section && group.section.title,
        icon: group.section && group.section.icon,
        pages: group.pages,
        subcategories: group.subcategories
      }
    end)
  end

  defp section_key(key) when is_map_key(@sections, key), do: key
  defp section_key(_key), do: nil

  def get_page!(category, subcategory, slug, locale \\ Glossia.I18n.default_locale())

  def get_page!(category, nil, slug, locale) do
    Enum.find(
      pages(locale),
      &(&1.category == category and is_nil(&1.subcategory) and &1.slug == slug)
    ) ||
      raise Glossia.Docs.NotFoundError, "doc page not found: #{category}/#{slug}"
  end

  def get_page!(category, subcategory, slug, locale) do
    Enum.find(
      pages(locale),
      &(&1.category == category and &1.subcategory == subcategory and &1.slug == slug)
    ) ||
      raise Glossia.Docs.NotFoundError, "doc page not found: #{category}/#{subcategory}/#{slug}"
  end

  def search_index(locale \\ Glossia.I18n.default_locale()) do
    Enum.map(all_pages(locale), fn page ->
      %{
        title: page.title,
        summary: page.summary,
        category: page.category,
        slug: page.slug,
        url: locale |> Glossia.I18n.localize_path(path_for(page)) |> String.trim_trailing("/"),
        headings: Enum.map(page.toc, &Map.take(&1, [:text, :id])),
        body_text: Glossia.MarketingMarkdown.strip_html(page.body)
      }
    end)
  end

  def markdown_only_pages(locale \\ Glossia.I18n.default_locale()) do
    Enum.filter(Map.get(@pages_by_locale, locale, @pages), & &1.markdown_only)
  end

  defp pages(locale) do
    Enum.reject(Map.get(@pages_by_locale, locale, @pages), & &1.markdown_only)
  end

  # The Diataxis labels live in code rather than in content, so they go through
  # Gettext instead of through the translated markdown.
  defp translate_section(%{key: key} = section),
    do: %{section | title: translated_section_title(key)}

  defp translated_section_title("translation"), do: gettext("Translation")
  defp translated_section_title("platform"), do: gettext("Platform")
  defp translated_section_title("analytics"), do: gettext("Analytics")
  defp translated_section_title("ecosystems"), do: gettext("Ecosystems")

  defp translate_meta(%{key: key} = meta) do
    %{meta | title: translated_title(key), summary: translated_summary(key)}
  end

  defp translated_title("tutorials"), do: gettext("Tutorials")
  defp translated_title("how-to"), do: gettext("How-to guides")
  defp translated_title("reference"), do: gettext("Reference")
  defp translated_title("explanation"), do: gettext("Explanation")
  defp translated_title("cli"), do: gettext("CLI")
  defp translated_title("apis"), do: gettext("APIs")
  defp translated_title("mcp"), do: gettext("MCP")

  defp translated_summary("tutorials"),
    do: gettext("Step-by-step lessons to get started with Glossia.")

  defp translated_summary("how-to"), do: gettext("Practical directions for specific tasks.")

  defp translated_summary("reference"),
    do: gettext("Technical descriptions of configuration, CLI, and APIs.")

  defp translated_summary("explanation"),
    do: gettext("Background, design decisions, and concepts.")

  defp translated_summary("cli"),
    do: gettext("Command-line tool documentation and release history.")

  defp translated_summary("apis"), do: gettext("Authentication and REST interfaces.")

  defp translated_summary("mcp"),
    do: gettext("Model Context Protocol server, tools, and prompts.")

  def path_for(%Page{subcategory: nil, category: category, slug: slug}) do
    path(%URI{}, ~p"/docs/#{category}/#{slug}")
  end

  def path_for(%Page{category: category, subcategory: subcategory, slug: slug}) do
    path(%URI{}, ~p"/docs/#{category}/#{subcategory}/#{slug}")
  end
end

defmodule Glossia.Docs.NotFoundError do
  defexception [:message, plug_status: 404]
end
