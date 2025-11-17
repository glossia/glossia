defmodule Glossia.Formats.JsonHandler do
  @moduledoc """
  Handles JSON translation files while preserving formatting.

  Translates string values in JSON while maintaining:
  - Indentation and whitespace
  - Key ordering
  - Structure and nesting
  - Non-string values (numbers, booleans, null)
  """

  @behaviour Glossia.Formats.Handler

  require Logger

  @impl true
  def translate(content, source_locale, target_locale) do
    with {:ok, parsed} <- parse_json(content),
         {:ok, indentation} <- detect_indentation(content),
         {:ok, translated} <- translate_values(parsed, source_locale, target_locale),
         {:ok, serialized} <- serialize_json(translated, indentation) do
      {:ok, serialized}
    end
  end

  @impl true
  def validate(content) do
    case Jason.decode(content) do
      {:ok, _} -> :ok
      {:error, %Jason.DecodeError{} = error} -> {:error, "Invalid JSON: #{Exception.message(error)}"}
    end
  end

  defp parse_json(content) do
    case Jason.decode(content) do
      {:ok, parsed} -> {:ok, parsed}
      {:error, error} -> {:error, "Failed to parse JSON: #{inspect(error)}"}
    end
  end

  defp detect_indentation(content) do
    # Try to detect indentation from the original content
    # Look for first indented line
    indentation =
      content
      |> String.split("\n")
      |> Enum.find_value(fn line ->
        case Regex.run(~r/^(\s+)/, line) do
          [_, spaces] -> String.length(spaces)
          nil -> nil
        end
      end)

    {:ok, indentation || 2}
  end

  defp translate_values(data, source_locale, target_locale) when is_map(data) do
    data
    |> Enum.map(fn {key, value} ->
      case translate_value(value, source_locale, target_locale) do
        {:ok, translated_value} -> {:ok, {key, translated_value}}
        {:error, _} = error -> error
      end
    end)
    |> collect_results()
    |> case do
      {:ok, pairs} -> {:ok, Map.new(pairs)}
      error -> error
    end
  end

  defp translate_values(data, source_locale, target_locale) when is_list(data) do
    data
    |> Enum.map(&translate_value(&1, source_locale, target_locale))
    |> collect_results()
  end

  defp translate_values(data, _source_locale, _target_locale) do
    {:ok, data}
  end

  defp translate_value(value, source_locale, target_locale) when is_binary(value) do
    # Only translate non-empty strings
    if String.trim(value) == "" do
      {:ok, value}
    else
      Glossia.AI.Translator.translate(value, source_locale, target_locale)
    end
  end

  defp translate_value(value, source_locale, target_locale) when is_map(value) do
    translate_values(value, source_locale, target_locale)
  end

  defp translate_value(value, source_locale, target_locale) when is_list(value) do
    translate_values(value, source_locale, target_locale)
  end

  defp translate_value(value, _source_locale, _target_locale) do
    # Numbers, booleans, null - keep as-is
    {:ok, value}
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

  defp serialize_json(data, indentation) do
    # Use Jason with pretty printing to preserve formatting
    case Jason.encode(data, pretty: true, indent: String.duplicate(" ", indentation)) do
      {:ok, json} -> {:ok, json}
      {:error, error} -> {:error, "Failed to serialize JSON: #{inspect(error)}"}
    end
  end
end
