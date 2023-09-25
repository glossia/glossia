defmodule Glossia.Features.Cloud.Marketing.Core.Blog.Authors do
  alias Glossia.Features.Cloud.Marketing.Core.Blog.Author

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

  def all, do: @all_authors
end
