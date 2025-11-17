defmodule Glossia.Formats.PoHandler do
  @moduledoc """
  Handles Gettext PO (Portable Object) files while preserving formatting.
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
  def validate(content) do
    # Basic PO file validation
    if String.contains?(content, "msgid") and String.contains?(content, "msgstr") do
      :ok
    else
      {:error, "Invalid PO file: missing msgid or msgstr"}
    end
  end

  defp translate_lines([], _source, _target, acc), do: {:ok, acc}

  defp translate_lines([line | rest], source, target, acc) do
    cond do
      # msgstr line - translate the value
      String.starts_with?(String.trim(line), "msgstr") ->
        case extract_and_translate_msgstr(line, source, target) do
          {:ok, translated_line} ->
            translate_lines(rest, source, target, [translated_line | acc])

          {:error, _} = error ->
            error
        end

      # Other lines - keep as-is
      true ->
        translate_lines(rest, source, target, [line | acc])
    end
  end

  defp extract_and_translate_msgstr(line, source, target) do
    case Regex.run(~r/msgstr\s+"(.*?)"/, line) do
      [full_match, value] when value != "" ->
        case Glossia.AI.TranslatorClient.translate(value, source, target) do
          {:ok, translated} ->
            {:ok, String.replace(line, full_match, "msgstr \"#{translated}\"")}

          error ->
            error
        end

      _ ->
        # Empty msgstr or no match, keep as-is
        {:ok, line}
    end
  end
end
