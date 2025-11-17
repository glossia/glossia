defmodule Glossia.Formats.PoHandler do
  @moduledoc """
  Handles Gettext PO (Portable Object) files while preserving formatting.

  This handler validates PO syntax and translates content using AI
  with format-aware instructions.
  """

  @behaviour Glossia.Formats.Handler

  alias Glossia.AI.Translator

  @format_instructions """
  This is a Gettext PO (Portable Object) localization file. You MUST:
  - Preserve ALL msgid entries exactly as they are
  - Preserve ALL comments (lines starting with #)
  - Preserve ALL metadata and headers
  - Preserve ALL formatting, spacing, and line structure
  - Translate ONLY the msgstr values (text after msgstr)
  - Keep all empty msgstr "" entries empty
  - Maintain the exact same PO file structure

  The output MUST be valid PO syntax with the exact same structure as the input.
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
    # Validate PO file structure and syntax
    with :ok <- validate_required_keywords(content),
         :ok <- validate_structure(content) do
      :ok
    end
  end

  defp validate_required_keywords(content) do
    cond do
      not String.contains?(content, "msgid") ->
        {:error, "Invalid PO file: missing msgid keyword"}

      not String.contains?(content, "msgstr") ->
        {:error, "Invalid PO file: missing msgstr keyword"}

      true ->
        :ok
    end
  end

  defp validate_structure(content) do
    # Check for basic PO structure: msgid followed by msgstr patterns
    # Split into lines and validate pairing
    lines = String.split(content, "\n")
    validate_msgid_msgstr_pairs(lines)
  end

  defp validate_msgid_msgstr_pairs(lines) do
    # Find all msgid and msgstr entries
    msgid_count = Enum.count(lines, &String.starts_with?(String.trim(&1), "msgid"))
    msgstr_count = Enum.count(lines, &String.starts_with?(String.trim(&1), "msgstr"))

    cond do
      msgid_count == 0 or msgstr_count == 0 ->
        {:error, "Invalid PO file: no valid msgid/msgstr entries found"}

      msgid_count != msgstr_count ->
        {:error, "Invalid PO file: mismatched msgid and msgstr entries"}

      true ->
        :ok
    end
  end
end
