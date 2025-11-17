defmodule Glossia.Formats.FtlHandler do
  @moduledoc """
  Handles Mozilla Fluent (.ftl) files while preserving formatting.

  Fluent is Mozilla's modern localization format used in Pontoon.
  Format: key = value (with support for attributes, variants, etc.)

  Example:
    hello = Hello, World!
    welcome-message = Welcome, {$name}!

  See: https://projectfluent.org/
  """

  @behaviour Glossia.Formats.Handler

  @impl true
  def translate(content, source_locale, target_locale) do
    content
    |> String.split("\n")
    |> translate_lines(source_locale, target_locale, [])
    |> case do
      {:ok, lines} -> {:ok, Enum.join(Enum.reverse(lines), "\n")}
      error -> error
    end
  end

  @impl true
  def validate(_content) do
    # Basic validation - Fluent files are text-based
    # Could add more strict FTL syntax validation if needed
    :ok
  end

  defp translate_lines([], _source, _target, acc), do: {:ok, acc}

  defp translate_lines([line | rest], source, target, acc) do
    cond do
      # Comment lines (# or ##)
      String.starts_with?(String.trim(line), "#") ->
        translate_lines(rest, source, target, [line | acc])

      # Empty lines
      String.trim(line) == "" ->
        translate_lines(rest, source, target, [line | acc])

      # Message with = (key = value)
      String.contains?(line, "=") ->
        case translate_ftl_line(line, source, target) do
          {:ok, translated_line} ->
            translate_lines(rest, source, target, [translated_line | acc])

          {:error, _} = error ->
            error
        end

      # Attributes or multiline (indented) - keep as-is for now
      # More sophisticated handling could be added
      true ->
        translate_lines(rest, source, target, [line | acc])
    end
  end

  defp translate_ftl_line(line, source, target) do
    case String.split(line, "=", parts: 2) do
      [_key, value] ->
        trimmed_value = String.trim(value)

        # Don't translate if empty or if it's just variables
        if trimmed_value == "" or only_variables?(trimmed_value) do
          {:ok, line}
        else
          # Extract the text parts (not the variables)
          case translate_fluent_value(trimmed_value, source, target) do
            {:ok, translated} ->
              # Preserve the indentation/spacing around the =
              [before_equal, _] = String.split(line, "=", parts: 2)
              {:ok, "#{before_equal}= #{translated}"}

            error ->
              error
          end
        end

      _ ->
        {:ok, line}
    end
  end

  defp translate_fluent_value(value, source, target) do
    # For now, translate the whole value including variables
    # The AI should preserve {$variable} syntax
    # More sophisticated parsing could separate text from variables
    Glossia.AI.TranslatorClient.translate(value, source, target)
  end

  defp only_variables?(text) do
    # Check if the text only contains variables like {$var}
    String.replace(text, ~r/\{\$[^}]+\}/, "")
    |> String.trim()
    |> String.length() == 0
  end
end
