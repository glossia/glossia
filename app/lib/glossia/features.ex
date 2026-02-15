defmodule Glossia.Features do
  alias Glossia.Features.Page

  use NimblePublisher,
    build: Page,
    from: Application.app_dir(:glossia, "priv/features/**/*.md"),
    as: :pages,
    earmark_options: %Earmark.Options{code_class_prefix: "language-"}

  @pages Enum.sort_by(@pages, & &1.order, :asc)

  def all_pages, do: @pages

  def get_page_by_slug!(slug) do
    Enum.find(@pages, &(&1.slug == slug)) ||
      raise Glossia.Features.NotFoundError, "feature page with slug=#{slug} not found"
  end
end

defmodule Glossia.Features.NotFoundError do
  defexception [:message, plug_status: 404]
end
