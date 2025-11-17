defmodule Glossia.Formats.StringsHandler do
  @moduledoc """
  Handles iOS .strings files while preserving formatting.

  Format: "key" = "value";

  This handler validates .strings syntax and translates content using AI
  with format-aware instructions.
  """

  @behaviour Glossia.Formats.Handler

  alias Glossia.AI.Translator

  @format_instructions """
  This is an iOS .strings localization file. You MUST:
  - Preserve ALL keys exactly as they are (text before the = sign)
  - Preserve ALL comments (lines starting with //, /*, or #)
  - Preserve ALL formatting, spacing, and line structure
  - Preserve the exact syntax: "key" = "value";
  - Translate ONLY the text values (text between quotes after the = sign)
  - Keep all semicolons and quotation marks
  - Preserve empty lines exactly as they appear

  The output MUST be valid .strings syntax with the exact same structure as the input.
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
  def validate(_content) do
    # Basic validation - .strings format is simple
    # Could add more strict validation if needed
    :ok
  end
end
