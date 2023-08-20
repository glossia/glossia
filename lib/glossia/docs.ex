defmodule Glossia.Docs do
  @moduledoc """
  A module that loads Markdown-writen docs at compile-time.
  """

  alias Glossia.Docs.{Page}

  use NimblePublisher,
    build: Page,
    from: Application.app_dir(:glossia, "priv/docs/pages/**/*.md"),
    as: :pages,
    highlighters: [:makeup_elixir, :makeup_erlang]

  # @posts Enum.sort_by(@pages, & &1.date, {:desc, Date})

  @spec all_pages() :: [Glossia.Docs.Page.t()]
  def all_pages, do: @pages
end
