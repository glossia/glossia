defmodule Glossia.Docs.Models.Page do
  use TypedStruct
  alias Glossia.Support.Directories
  @derive Nestru.Decoder

  typedstruct do
    field :slug, String.t(), enforce: true
    field :title, String.t(), enforce: true
    field :description, String.t(), enforce: true
    field :tags, [String.t()], enforce: true
    field :body, String.t(), enforce: true
  end

  def build(filename, attrs, body) do
    pages_directory = Directories.priv() |> Path.join("docs/pages")
    slug = Path.relative_to(filename, pages_directory) |> String.replace(".md", "")
    Nestru.decode_from_map!(Map.merge(%{slug: slug, body: body}, attrs), __MODULE__)
  end
end
