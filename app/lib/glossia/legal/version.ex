defmodule Glossia.Legal.Version do
  @enforce_keys [:id, :document, :title, :date, :changes, :body]
  defstruct [:id, :document, :title, :date, :changes, :body]

  def build(filename, attrs, body) do
    id =
      filename
      |> Path.rootname()
      |> Path.split()
      |> List.last()

    document =
      filename
      |> Path.basename(".md")
      |> String.replace(~r/-\d{4}-\d{2}-\d{2}\z/, "")

    struct!(
      __MODULE__,
      Map.merge(attrs, %{id: id, document: document, body: body})
    )
  end
end
