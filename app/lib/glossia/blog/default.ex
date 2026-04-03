defmodule Glossia.Blog.Default do
  @moduledoc false

  alias Glossia.Blog.Post

  @behaviour Glossia.Blog.Source

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:glossia, "priv/blog/**/*.md"),
    as: :posts,
    earmark_options: %Earmark.Options{code_class_prefix: "language-"}

  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  @impl true
  def all_posts, do: @posts

  @impl true
  def recent_posts(count \\ 2), do: Enum.take(@posts, count)

  @impl true
  def get_post_by_slug!(slug) do
    Enum.find(@posts, &(&1.slug == slug)) ||
      raise Glossia.Blog.NotFoundError, "post with slug=#{slug} not found"
  end
end
