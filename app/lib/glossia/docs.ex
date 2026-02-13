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

  def pages_by_category(category) do
    Enum.filter(@pages, &(&1.category == category))
  end

  def get_page!(category, slug) do
    Enum.find(@pages, &(&1.category == category && &1.slug == slug)) ||
      raise Glossia.Docs.NotFoundError,
            "doc page with category=#{category} slug=#{slug} not found"
  end
end

defmodule Glossia.Docs.NotFoundError do
  defexception [:message, plug_status: 404]
end
