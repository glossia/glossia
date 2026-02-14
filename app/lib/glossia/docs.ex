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
      summary: "Technical descriptions of configuration, CLI, and file formats.",
      icon: "file-text"
    },
    "explanation" => %{
      title: "Explanation",
      summary: "Background, design decisions, and concepts.",
      icon: "lightbulb"
    }
  }

  def all_pages, do: @pages

  def categories, do: @categories

  def pages_by_category("reference") do
    api_page = %Page{
      id: "reference/api",
      title: "API Reference",
      summary: "Interactive reference for OAuth and discovery endpoints.",
      category: "reference",
      order: 10,
      slug: "api",
      body: ""
    }

    Enum.filter(@pages, &(&1.category == "reference")) ++ [api_page]
  end

  def pages_by_category(category) do
    Enum.filter(@pages, &(&1.category == category))
  end

  def get_page!(category, slug) do
    Enum.find(@pages, &(&1.category == category && &1.slug == slug)) ||
      raise Glossia.Docs.NotFoundError,
            "doc page with category=#{category} slug=#{slug} not found"
  end

  def search_index do
    compiled =
      Enum.map(@pages, fn page ->
        %{
          title: page.title,
          summary: page.summary,
          category: page.category,
          slug: page.slug,
          url: "/docs/#{page.category}/#{page.slug}",
          headings: Enum.map(page.toc, fn h -> %{text: h.text, id: h.id} end),
          body_text: strip_html(page.body)
        }
      end)

    api_entry = %{
      title: "API Reference",
      summary: "Interactive reference for OAuth and discovery endpoints.",
      category: "reference",
      slug: "api",
      url: "/docs/reference/api",
      headings: [],
      body_text: "OAuth token register revoke introspect well-known openapi endpoints API"
    }

    compiled ++ [api_entry]
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
