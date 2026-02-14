defmodule Glossia.Docs do
  alias Glossia.Docs.Page

  use NimblePublisher,
    build: Page,
    from: Application.app_dir(:glossia, "priv/docs/**/*.md"),
    as: :pages,
    earmark_options: %Earmark.Options{code_class_prefix: "language-"}

  @pages Enum.sort_by(@pages, & &1.order)

  @categories %{
    "tutorials" => %{
      title: "Tutorials",
      summary: "Step-by-step lessons to get started with Glossia.",
      icon: "book"
    },
    "how-to" => %{
      title: "How-to guides",
      summary: "Practical directions for specific tasks.",
      icon: "compass"
    },
    "reference" => %{
      title: "Reference",
      summary: "Technical descriptions of configuration, CLI, and APIs.",
      icon: "file-text"
    },
    "explanation" => %{
      title: "Explanation",
      summary: "Background, design decisions, and concepts.",
      icon: "lightbulb"
    }
  }

  @subcategories %{
    {"reference", "cli"} => %{
      title: "CLI",
      summary: "Command-line tool documentation and release history.",
      order: 2
    },
    {"reference", "apis"} => %{
      title: "APIs",
      summary: "Authentication and REST interfaces.",
      order: 3
    },
    {"reference", "mcp"} => %{
      title: "MCP",
      summary: "Model Context Protocol server, tools, and prompts.",
      order: 4
    }
  }

  @api_page %Page{
    id: "reference/apis/rest",
    title: "REST",
    summary: "Interactive reference for OAuth and discovery endpoints.",
    category: "reference",
    subcategory: "apis",
    order: 2,
    slug: "rest",
    body: ""
  }

  @mcp_tools_page Glossia.Docs.MCP.tools_page()
  @mcp_prompts_page Glossia.Docs.MCP.prompts_page()

  def all_pages, do: @pages

  def categories, do: @categories

  @doc """
  Returns top-level pages for a category (excludes pages that belong to a subcategory).
  """
  def pages_by_category(category) do
    Enum.filter(@pages, &(&1.category == category && is_nil(&1.subcategory)))
  end

  @doc """
  Returns subcategories for a given category, sorted by order.
  """
  def subcategories_for(category) do
    @subcategories
    |> Enum.filter(fn {{cat, _key}, _meta} -> cat == category end)
    |> Enum.map(fn {{_cat, key}, meta} -> Map.put(meta, :key, key) end)
    |> Enum.sort_by(& &1.order)
  end

  @doc """
  Returns subcategory metadata or raises NotFoundError.
  """
  def subcategory!(category, key) do
    Map.get(@subcategories, {category, key}) ||
      raise Glossia.Docs.NotFoundError,
            "subcategory #{category}/#{key} not found"
  end

  @doc """
  Returns pages within a specific subcategory.
  """
  def pages_by_subcategory("reference", "apis") do
    pages = Enum.filter(@pages, &(&1.category == "reference" && &1.subcategory == "apis"))
    pages ++ [@api_page]
  end

  def pages_by_subcategory("reference", "mcp") do
    pages = Enum.filter(@pages, &(&1.category == "reference" && &1.subcategory == "mcp"))
    pages ++ [@mcp_tools_page, @mcp_prompts_page]
  end

  def pages_by_subcategory(category, subcategory) do
    Enum.filter(@pages, &(&1.category == category && &1.subcategory == subcategory))
  end

  def get_page!(category, slug) do
    Enum.find(@pages, &(&1.category == category && is_nil(&1.subcategory) && &1.slug == slug)) ||
      raise Glossia.Docs.NotFoundError,
            "doc page with category=#{category} slug=#{slug} not found"
  end

  @synthetic_pages [@api_page, @mcp_tools_page, @mcp_prompts_page]

  def get_subcategory_page!(category, subcategory, slug) do
    Enum.find(
      @pages ++ @synthetic_pages,
      &(&1.category == category && &1.subcategory == subcategory && &1.slug == slug)
    ) ||
      raise Glossia.Docs.NotFoundError,
            "doc page with category=#{category} subcategory=#{subcategory} slug=#{slug} not found"
  end

  def search_index do
    compiled =
      Enum.map(@pages, fn page ->
        url =
          if page.subcategory do
            "/docs/#{page.category}/#{page.subcategory}/#{page.slug}"
          else
            "/docs/#{page.category}/#{page.slug}"
          end

        %{
          title: page.title,
          summary: page.summary,
          category: page.category,
          slug: page.slug,
          url: url,
          headings: Enum.map(page.toc, fn h -> %{text: h.text, id: h.id} end),
          body_text: strip_html(page.body)
        }
      end)

    synthetic_entries =
      Enum.map(@synthetic_pages, fn page ->
        %{
          title: page.title,
          summary: page.summary,
          category: page.category,
          slug: page.slug,
          url: "/docs/#{page.category}/#{page.subcategory}/#{page.slug}",
          headings: Enum.map(page.toc, fn h -> %{text: h.text, id: h.id} end),
          body_text: strip_html(page.body)
        }
      end)

    compiled ++ synthetic_entries
  end

  defp strip_html(html) do
    html
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end

defmodule Glossia.Docs.NotFoundError do
  defexception [:message, plug_status: 404]
end
