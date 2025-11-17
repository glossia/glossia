defmodule Glossia.Formats.YamlHandler do
  @moduledoc """
  Handles YAML translation files while preserving formatting.

  This handler validates YAML syntax and translates content using AI
  with format-aware instructions.
  """

  @behaviour Glossia.Formats.Handler

  alias Glossia.AI.Translator

  @format_instructions """
  This is a YAML localization file. You MUST:
  - Preserve ALL keys exactly as they are
  - Preserve ALL structure, nesting, and indentation
  - Preserve ALL comments (lines starting with #)
  - Translate ONLY the string values
  - Keep all non-string values unchanged (numbers, booleans, null, lists, etc.)
  - Maintain the exact same YAML structure

  The output MUST be valid YAML with the exact same structure as the input.
  """

  @impl true
  def translate(content, source_locale, target_locale) do
    with :ok <- validate(content),
         {:ok, translated_content} <-
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
    case YamlElixir.read_from_string(content) do
      {:ok, _} -> :ok
      {:error, %YamlElixir.ParsingError{} = error} ->
        {:error, "Invalid YAML: #{Exception.message(error)}"}

      {:error, error} ->
        {:error, "Invalid YAML: #{inspect(error)}"}
    end
  end
end
