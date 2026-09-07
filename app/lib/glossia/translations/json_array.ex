defmodule Glossia.Translations.JsonArray do
  @moduledoc """
  Decodes a JSON array from a model response.

  Translation recovery asks models to return arrays of strings. Models sometimes
  place an otherwise-valid array in a Markdown code fence, occasionally after a
  short introductory sentence. Some return that final array without the fence.
  All callers still validate the array's shape and length before using it.
  """

  def decode(text) when is_binary(text) do
    text
    |> candidates()
    |> Enum.find_value({:error, :invalid_json_array}, fn candidate ->
      case JSON.decode(candidate) do
        {:ok, values} when is_list(values) -> {:ok, values}
        _ -> false
      end
    end)
  end

  defp candidates(text) do
    trimmed = String.trim(text)

    fenced =
      Regex.scan(~r/```(?:json)?\s*\r?\n(.*?)\r?\n```/is, trimmed, capture: :all_but_first)
      |> Enum.map(fn [content] -> String.trim(content) end)

    [trimmed | fenced ++ trailing_arrays(trimmed)]
    |> Enum.uniq()
  end

  # Only consider an unfenced array when it consumes the end of the response.
  # This accepts a model's brief introduction followed by its requested JSON
  # while avoiding an earlier array it may have quoted as an example.
  defp trailing_arrays(text) do
    text
    |> :binary.matches("[")
    |> Enum.reverse()
    |> Enum.map(fn {offset, _length} ->
      binary_part(text, offset, byte_size(text) - offset)
      |> String.trim()
    end)
  end
end
