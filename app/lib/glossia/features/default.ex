defmodule Glossia.Features.Default do
  @moduledoc false

  alias Glossia.Features.Page

  @behaviour Glossia.Features.Source

  use NimblePublisher,
    build: Page,
    from: Application.app_dir(:glossia, "priv/features/**/*.md"),
    as: :pages,
    earmark_options: %Earmark.Options{code_class_prefix: "language-"}

  @pages Enum.sort_by(@pages, & &1.order, :asc)

  @impl true
  def all_pages, do: @pages

  @impl true
  def get_page_by_slug!(slug) do
    Enum.find(@pages, &(&1.slug == slug)) ||
      raise Glossia.Features.NotFoundError, "feature page with slug=#{slug} not found"
  end
end
