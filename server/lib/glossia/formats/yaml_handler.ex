defmodule Glossia.Formats.YamlHandler do
  @moduledoc """
  Handles YAML translation files while preserving formatting.
  """

  @behaviour Glossia.Formats.Handler

  require Logger

  @impl true
  def translate(content, source_locale, target_locale) do
    with {:ok, parsed} <- parse_yaml(content),
         {:ok, translated} <- translate_values(parsed, source_locale, target_locale),
         {:ok, serialized} <- serialize_yaml(translated) do
      {:ok, serialized}
    end
  end

  @impl true
  def validate(content) do
    case YamlElixir.read_from_string(content) do
      {:ok, _} -> :ok
      {:error, %YamlElixir.ParsingError{} = error} ->
        {:error, "Invalid YAML: #{Exception.message(error)}"}
      {:error, error} ->
        {:error, "Invalid YAML: #{inspect(error)}"}
    end
  end

  defp parse_yaml(content) do
    case YamlElixir.read_from_string(content) do
      {:ok, parsed} -> {:ok, parsed}
      {:error, error} -> {:error, "Failed to parse YAML: #{inspect(error)}"}
    end
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
    if String.trim(value) == "" do
      {:ok, value}
    else
      Glossia.AI.TranslatorClient.translate(value, source_locale, target_locale)
    end
  end

  defp translate_value(value, source_locale, target_locale) when is_map(value) do
    translate_values(value, source_locale, target_locale)
  end

  defp translate_value(value, source_locale, target_locale) when is_list(value) do
    translate_values(value, source_locale, target_locale)
  end

  defp translate_value(value, _source_locale, _target_locale) do
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

  defp serialize_yaml(data) do
    # YamlElixir doesn't have write_to_string, use Yamerl for encoding
    try do
      yaml = :yamerl.encode(data) |> IO.iodata_to_binary()
      {:ok, yaml}
    rescue
      e -> {:error, "Failed to serialize YAML: #{Exception.message(e)}"}
    end
  end
end
