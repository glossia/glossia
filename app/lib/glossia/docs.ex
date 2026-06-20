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
    :order,
    :body,
    :toc,
    :raw_markdown,
    :markdown,
    :kind
  ]

  def build(filename, attrs, body) do
    {category, subcategory, slug, id} = path_parts(filename)
    {body, toc} = Glossia.MarketingMarkdown.process(body, toc: true)

    attrs
    |> Map.put_new(:category, category)
    |> Map.put_new(:subcategory, subcategory)
    |> Map.put_new(:slug, slug)
    |> Map.put_new(:kind, :doc)
    |> Map.merge(%{
      id: id,
      body: body,
      toc: toc,
      raw_markdown: raw_markdown(filename),
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

  defp raw_markdown(filename) do
    filename
    |> File.read!()
    |> String.split("\n---\n", parts: 2)
    |> List.last()
    |> String.trim()
  end
end

defmodule Glossia.Docs do
  @moduledoc false

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
      icon: "compass"
    },
    "reference" => %{
      key: "reference",
      title: "Reference",
      summary: "Technical descriptions of configuration, CLI, and APIs.",
      icon: "file-text"
    },
    "explanation" => %{
      key: "explanation",
      title: "Explanation",
      summary: "Background, design decisions, and concepts.",
      icon: "lightbulb"
    }
  }

  @subcategories %{
    "reference/cli" => %{
      category: "reference",
      key: "cli",
      title: "CLI",
      summary: "Command-line tool documentation and release history.",
      order: 2
    },
    "reference/apis" => %{
      category: "reference",
      key: "apis",
      title: "APIs",
      summary: "Authentication and REST interfaces.",
      order: 3
    },
    "reference/mcp" => %{
      category: "reference",
      key: "mcp",
      title: "MCP",
      summary: "Model Context Protocol server, tools, and prompts.",
      order: 4
    }
  }

  use NimblePublisher,
    build: Page,
    from: Application.app_dir(:glossia, "priv/docs/**/*.md"),
    as: :content_pages,
    earmark_options: %Earmark.Options{code_class_prefix: "language-"}

  @content_pages Enum.sort_by(@content_pages, & &1.order)

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

  def categories, do: @categories

  def sorted_categories do
    @category_order
    |> Enum.map(&{&1, Map.fetch!(@categories, &1)})
    |> Enum.filter(fn {category, _meta} -> category_items(category) != [] end)
    |> Map.new()
  end

  def category_meta!(category), do: Map.fetch!(@categories, category)

  def subcategory_meta!(category, subcategory) do
    Map.fetch!(@subcategories, "#{category}/#{subcategory}")
  end

  def subcategory?(category, subcategory) do
    Map.has_key?(@subcategories, "#{category}/#{subcategory}")
  end

  def category_items(category) do
    page_items =
      @pages
      |> Enum.filter(
        &(&1.category == category and is_nil(&1.subcategory) and &1.id != "reference/api")
      )
      |> Enum.map(&%{title: &1.title, summary: &1.summary, href: path_for(&1), order: &1.order})

    subcategory_items =
      @subcategories
      |> Map.values()
      |> Enum.filter(&(&1.category == category and subcategory_pages(category, &1.key) != []))
      |> Enum.map(
        &%{
          title: &1.title,
          summary: &1.summary,
          href: "/docs/#{category}/#{&1.key}",
          order: &1.order
        }
      )

    Enum.sort_by(page_items ++ subcategory_items, & &1.order)
  end

  def subcategory_pages(category, subcategory) do
    @pages
    |> Enum.filter(&(&1.category == category and &1.subcategory == subcategory))
    |> Enum.sort_by(& &1.order)
  end

  def all_pages do
    Enum.reject(@pages, &(&1.id == "reference/api"))
  end

  def get_page!(category, nil, slug) do
    Enum.find(@pages, &(&1.category == category and is_nil(&1.subcategory) and &1.slug == slug)) ||
      raise Glossia.Docs.NotFoundError, "doc page not found: #{category}/#{slug}"
  end

  def get_page!(category, subcategory, slug) do
    Enum.find(
      @pages,
      &(&1.category == category and &1.subcategory == subcategory and &1.slug == slug)
    ) ||
      raise Glossia.Docs.NotFoundError, "doc page not found: #{category}/#{subcategory}/#{slug}"
  end

  def search_index do
    Enum.map(all_pages(), fn page ->
      %{
        title: page.title,
        summary: page.summary,
        category: page.category,
        slug: page.slug,
        url: String.trim_trailing(path_for(page), "/"),
        headings: Enum.map(page.toc, &Map.take(&1, [:text, :id])),
        body_text: Glossia.MarketingMarkdown.strip_html(page.body)
      }
    end)
  end

  def path_for(%Page{subcategory: nil, category: category, slug: slug}) do
    "/docs/#{category}/#{slug}"
  end

  def path_for(%Page{category: category, subcategory: subcategory, slug: slug}) do
    "/docs/#{category}/#{subcategory}/#{slug}"
  end
end

defmodule Glossia.Docs.NotFoundError do
  defexception [:message, plug_status: 404]
end
