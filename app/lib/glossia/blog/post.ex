defmodule Glossia.Blog.Post do
  @enforce_keys [:id, :title, :summary, :date, :slug, :body, :author]
  defstruct [:id, :title, :summary, :date, :slug, :body, :author]

  def build(filename, attrs, body) do
    [year, month, day, id] =
      filename
      |> Path.rootname()
      |> Path.split()
      |> List.last()
      |> String.split("-", parts: 4)

    date = Date.from_iso8601!("#{year}-#{month}-#{day}")
    slug = Map.get(attrs, :slug, id)
    author = Glossia.Blog.Author.get!(attrs.author)

    struct!(
      __MODULE__,
      Map.merge(attrs, %{id: id, date: date, body: body, slug: slug, author: author})
    )
  end
end
