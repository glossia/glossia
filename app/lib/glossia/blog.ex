defmodule Glossia.Blog do
  alias Glossia.Blog.Post

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:glossia, "priv/blog/**/*.md"),
    as: :posts,
    earmark_options: %Earmark.Options{code_class_prefix: "language-"}

  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  def all_posts, do: @posts

  def recent_posts(count \\ 2), do: Enum.take(@posts, count)

  def get_post_by_slug!(slug) do
    Enum.find(@posts, &(&1.slug == slug)) ||
      raise Glossia.Blog.NotFoundError, "post with slug=#{slug} not found"
  end
end

defmodule Glossia.Blog.NotFoundError do
  defexception [:message, plug_status: 404]
end
