defmodule Glossia.Changelog.Update do
  @moduledoc """
  A struct that represents a changelog update.
  Updates are loaded and serialized at compile-time by `Glossia.Changelog`.
  """

  @type t :: %__MODULE__{
          body: String.t(),
          date: Date.t()
        }

  @enforce_keys [:date, :body]
  defstruct [:date, :body]

  def build(filename, attrs, body) do
    filename_last_component =
      filename
      |> Path.rootname()
      |> Path.split()
      |> List.last()

    [year, month, day] =
      filename_last_component
      |> String.split("-")
      |> Enum.take(3)

    date_string = "#{year}-#{month}-#{day}"
    date = date_string |> Date.from_iso8601!()
    struct!(__MODULE__, [date: date, body: body] ++ Map.to_list(attrs))
  end
end
