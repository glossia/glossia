defmodule Glossia.Blog do
  @moduledoc """
  A module that loads Markdown-writen blog posts at compile-time.
  """
  use Boundary, deps: [], exports: []

  alias Glossia.Blog.{Post, Author}

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:glossia, "priv/blog/posts/**/*.md"),
    as: :posts,
    highlighters: [:makeup_elixir, :makeup_erlang]

  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})
  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  @external_resource Path.relative_to_cwd("priv/blog/authors.json")
  @authors File.read!("priv/blog/authors.json")
           |> Jason.decode!(keys: :atoms)
           |> Enum.map(fn {key, value} -> struct!(Author, Map.put(value, :id, key)) end)

  @spec all_posts() :: [Glossia.Blog.Post.t()]
  def all_posts, do: @posts

  @spec all_tags() :: [String.t()]
  def all_tags, do: @tags

  @spec all_authors() :: [Glossia.Blog.Author.t()]
  def all_authors, do: @authors
end
