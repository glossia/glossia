defmodule Glossia.Formats.PropertiesHandler do
  @moduledoc """
  Handles Java .properties files while preserving formatting.
  Format: key=value pairs, one per line
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
    # Properties files are line-based key=value, always valid as text
    # We could add more strict validation if needed
    :ok
  end

  defp translate_line(line, source_locale, target_locale) do
    cond do
      # Comment or empty line
      String.starts_with?(String.trim(line), ["#", "!"]) or String.trim(line) == "" ->
        {:ok, line}

      # Key=value pair
      String.contains?(line, "=") ->
        [key | value_parts] = String.split(line, "=", parts: 2)
        value = Enum.join(value_parts, "=")

        case Glossia.AI.TranslatorClient.translate(value, source_locale, target_locale) do
          {:ok, translated} -> {:ok, "#{key}=#{translated}"}
          error -> error
        end

      # Invalid line, keep as-is
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
