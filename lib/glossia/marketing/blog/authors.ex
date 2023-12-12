defmodule Glossia.Marketing.Blog.Authors do
  alias Glossia.Marketing.Blog.Author

  @moduledoc """
  An interface that provides all the authors
  """
  @all_authors "priv/blog/authors.json"
               |> File.read!()
               |> Jason.decode!(keys: :atoms)
               |> Enum.map(fn value ->
                 Nestru.decode_from_map!(value, Author)
               end)
  @external_resource "priv/blog/authors.json"

  @spec all :: any()
  def all, do: @all_authors
end
