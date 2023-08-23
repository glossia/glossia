defmodule Glossia.Changelog do
  @moduledoc """
  A module that loads Markdown-writen blog posts at compile-time.
  """

  alias Glossia.Changelog.{Update}
  use Boundary
  use NimblePublisher,
    build: Update,
    from: Application.app_dir(:glossia, "priv/changelog/updates/**/*.md"),
    as: :updates,
    highlighters: [:makeup_elixir, :makeup_erlang]

  @updates Enum.sort_by(@updates, & &1.date, {:desc, Date})

  @spec all_updates() :: [Glossia.Blog.Post.t()]
  def all_updates, do: @updates
end
