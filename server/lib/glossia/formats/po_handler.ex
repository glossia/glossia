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
    # Basic PO file validation
    if String.contains?(content, "msgid") and String.contains?(content, "msgstr") do
      :ok
    else
      {:error, "Invalid PO file: missing msgid or msgstr"}
    end
  end
end
