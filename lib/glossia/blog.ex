defmodule Glossia.Marketing.Blog do
  @moduledoc false

  alias Glossia.Marketing.Blog.Authors
  alias Glossia.Marketing.Blog.{Post}

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:glossia, "priv/blog/posts/**/*.md"),
    as: :posts,
    highlighters: [:makeup_elixir, :makeup_erlang]

  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})
  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  def all_authors, do: Authors.all()

  @spec all_posts() :: [Post.t()]
  def all_posts, do: @posts

  @spec all_tags() :: [String.t()]
  def all_tags, do: @tags
end
