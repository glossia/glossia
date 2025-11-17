defmodule Glossia.Formats.PropertiesHandler do
  @moduledoc """
  Handles Java .properties files while preserving formatting.

  Format: key=value pairs, one per line

  This handler validates .properties syntax and translates content using AI
  with format-aware instructions.
  """

  @behaviour Glossia.Formats.Handler

  alias Glossia.AI.Translator

  @format_instructions """
  This is a Java .properties localization file. You MUST:
  - Preserve ALL keys exactly as they are (text before the = sign)
  - Preserve ALL comments (lines starting with # or !)
  - Preserve ALL formatting, spacing, and line structure
  - Preserve the exact syntax: key=value
  - Translate ONLY the values (text after the = sign)
  - Preserve empty lines exactly as they appear

  The output MUST be valid .properties syntax with the exact same structure as the input.
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
    # Properties files are line-based key=value, always valid as text
    # Could add more strict validation if needed
    :ok
  end
end
