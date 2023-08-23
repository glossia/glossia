defmodule Glossia.Blog do
  @moduledoc """
  A module that loads Markdown-writen blog posts at compile-time.
  """

  # Modules
  alias Glossia.Blog.{Post}
  use Boundary

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:glossia, "priv/blog/posts/**/*.md"),
    as: :posts,
    highlighters: [:makeup_elixir, :makeup_erlang]

  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})
  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  @spec all_authors() :: [Glossia.Blog.Authors.t()]
  def all_authors, do: Glossia.Blog.Authors.all()

  @spec all_posts() :: [Glossia.Blog.Post.t()]
  def all_posts, do: @posts

  @spec all_tags() :: [String.t()]
  def all_tags, do: @tags
end
