defmodule Glossia.Legal.Version do
  @enforce_keys [:id, :document, :title, :date, :changes, :body]
  defstruct [:id, :document, :title, :date, :changes, :body]

  def build(filename, attrs, body) do
    id =
      filename
      |> Path.rootname()
      |> Path.split()
      |> List.last()

    struct!(
      __MODULE__,
      Map.merge(attrs, %{id: id, body: body})
    )
  end
end
