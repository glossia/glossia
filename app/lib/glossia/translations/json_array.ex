defmodule Glossia.Translations.JsonArray do
  @moduledoc """
  Decodes a JSON array from a model response.

  Translation recovery asks models to return arrays of strings. Models sometimes
  place an otherwise-valid array in a Markdown code fence, occasionally after a
  short introductory sentence. We accept only the fenced JSON payload itself;
  all callers still validate the array's shape and length before using it.
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

    [trimmed | fenced]
  end
end
