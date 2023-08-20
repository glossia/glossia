defmodule Glossia.Blog.Authors do
  @moduledoc """
  An interface that provides all the authors
  """
  @all_authors "priv/blog/authors.json"
               |> File.read!()
               |> Jason.decode!(keys: :atoms)
               |> Enum.map(fn {key, value} ->
                 struct!(Glossia.Blog.Author, Map.put(value, :id, key))
               end)
  @external_resource "priv/blog/authors.json"

  def all, do: @all_authors
end
