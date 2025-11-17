defmodule Glossia.Formats.StringsHandler do
  @moduledoc """
  Handles iOS .strings files while preserving formatting.
  Format: "key" = "value";
  """

  @behaviour Glossia.Formats.Handler

  @impl true
  def translate(content, source_locale, target_locale) do
    content
    |> String.split("\n")
    |> Enum.map(&translate_line(&1, source_locale, target_locale))
    |> collect_results()
    |> case do
      {:ok, lines} -> {:ok, Enum.join(lines, "\n")}
      error -> error
    end
  end

  @impl true
  def validate(_content) do
    # Basic validation - could be more strict
    :ok
  end

  defp translate_line(line, source_locale, target_locale) do
    cond do
      # Comment or empty line
      String.starts_with?(String.trim(line), ["/*", "//", "#"]) or String.trim(line) == "" ->
        {:ok, line}

      # "key" = "value"; pattern
      String.contains?(line, "=") and String.contains?(line, "\"") ->
        case Regex.run(~r/"([^"]*?)"\s*=\s*"([^"]*?)";/, line) do
          [_, key, value] ->
            case Glossia.AI.Translator.translate(value, source_locale, target_locale) do
              {:ok, translated} -> {:ok, "\"#{key}\" = \"#{translated}\";"}
              error -> error
            end

          nil ->
            {:ok, line}
        end

      # Keep as-is
      true ->
        {:ok, line}
    end
  end

  defp collect_results(results) do
    Enum.reduce_while(results, {:ok, []}, fn
      {:ok, value}, {:ok, acc} -> {:cont, {:ok, [value | acc]}}
      {:error, _} = error, _acc -> {:halt, error}
    end)
    |> case do
      {:ok, values} -> {:ok, Enum.reverse(values)}
      error -> error
    end
  end
end
