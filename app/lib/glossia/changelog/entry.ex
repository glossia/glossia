defmodule Glossia.Changelog.Entry do
  @enforce_keys [:id, :title, :summary, :date, :slug, :body]
  defstruct [:id, :title, :summary, :date, :slug, :body]

  def build(filename, attrs, body) do
    [year, month, day, id] =
      filename
      |> Path.rootname()
      |> Path.split()
      |> List.last()
      |> String.split("-", parts: 4)

    date = Date.from_iso8601!("#{year}-#{month}-#{day}")
    slug = Map.get(attrs, :slug, id)

    struct!(
      __MODULE__,
      Map.merge(attrs, %{id: id, date: date, body: body, slug: slug})
    )
  end
end
