defmodule Glossia.Formats.FtlHandler do
  @moduledoc """
  Handles Mozilla Fluent (.ftl) files while preserving formatting.

  Fluent is Mozilla's modern localization format used in Pontoon.
  Format: key = value (with support for attributes, variants, etc.)

  This handler validates FTL syntax using a Wasm module (written in Zig)
  and translates content using AI with format-aware instructions.

  Example:
    hello = Hello, World!
    welcome-message = Welcome, {$name}!

  See: https://projectfluent.org/
  """

  @behaviour Glossia.Formats.Handler

  alias Glossia.Formats.WasmHandler
  alias Glossia.AI.Translator

  @handler_name "ftl"

  # FTL-specific instructions for the LLM
  @format_instructions """
  This is a Mozilla Fluent (FTL) localization file. You MUST:
  - Preserve ALL keys exactly as they are (keys before the = sign)
  - Preserve ALL comments (lines starting with #)
  - Preserve ALL formatting, spacing, and line structure
  - Preserve ALL variables and placeholders like {$name}, {$count}, etc.
  - Translate ONLY the text values after the = sign
  - Do NOT translate indented lines starting with a dot (attributes like .aria-label)
  - Do NOT translate values that contain only variables like "{$value}"
  - Preserve empty lines exactly as they appear

  The output MUST be valid FTL syntax with the exact same structure as the input.
  """

  @impl true
  def translate(content, source_locale, target_locale) do
    # First validate the input content
    with :ok <- validate(content),
         # Translate with format-specific instructions
         {:ok, translated_content} <-
           Translator.translate_with_instructions(
             content,
             source_locale,
             target_locale,
             @format_instructions
           ),
         # Validate the output to ensure it's still valid FTL
         :ok <- validate(translated_content) do
      {:ok, translated_content}
    end
  end

  @impl true
  def validate(content) do
    WasmHandler.validate(@handler_name, content)
  end
end
