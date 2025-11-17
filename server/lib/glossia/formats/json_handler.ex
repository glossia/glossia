defmodule Glossia.Formats.JsonHandler do
  @moduledoc """
  Handles JSON translation files while preserving formatting.

  This handler validates JSON syntax and translates content using AI
  with format-aware instructions.
  """

  @behaviour Glossia.Formats.Handler

  alias Glossia.AI.Translator

  @format_instructions """
  This is a JSON localization file. You MUST:
  - Preserve ALL keys exactly as they are
  - Preserve ALL structure, nesting, and formatting
  - Preserve ALL indentation and whitespace
  - Translate ONLY the string values
  - Keep all non-string values unchanged (numbers, booleans, null, arrays of non-strings)
  - Maintain the exact same JSON structure and key ordering

  The output MUST be valid JSON with the exact same structure as the input.
  """

  @impl true
  def translate(content, source_locale, target_locale) do
    with {:ok, translated_content} <-
           Translator.translate_with_instructions(
             content,
             source_locale,
             target_locale,
             @format_instructions
           ),
         :ok <- validate(translated_content) do
      {:ok, translated_content}
    end
  end

  @impl true
  def validate(content) do
    case Jason.decode(content) do
      {:ok, _} -> :ok
      {:error, %Jason.DecodeError{} = error} ->
        {:error, "Invalid JSON: #{Exception.message(error)}"}
    end
  end
end
