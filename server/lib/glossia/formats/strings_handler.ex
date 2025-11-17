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
  def validate(content) do
    # Validate .strings file structure
    lines = String.split(content, "\n")
    validate_strings_lines(lines, 1, :normal)
  end

  # State machine: :normal (outside comment), :block_comment (inside /* */ comment)
  defp validate_strings_lines([], _line_num, _state), do: :ok

  defp validate_strings_lines([line | rest], line_num, state) do
    trimmed = String.trim(line)

    # Handle block comment state transitions
    {new_state, is_block_comment_line} =
      cond do
        # Currently in block comment and line ends it
        state == :block_comment and String.contains?(line, "*/") -> {:normal, true}
        # Currently in block comment
        state == :block_comment -> {:block_comment, true}
        # Start a block comment
        String.contains?(line, "/*") -> {:block_comment, true}
        # Normal state
        true -> {state, false}
      end

    # Skip empty lines, line comments, and block comment lines
    if trimmed == "" or String.starts_with?(trimmed, "//") or String.starts_with?(trimmed, "#") or
         is_block_comment_line do
      validate_strings_lines(rest, line_num + 1, new_state)
    else
      # Check for valid "key" = "value"; format
      # Must have at least one = and end with semicolon (allowing whitespace)
      trimmed_for_semicolon = String.trim_trailing(trimmed)

      if String.contains?(trimmed, "=") and String.ends_with?(trimmed_for_semicolon, ";") do
        validate_strings_lines(rest, line_num + 1, new_state)
      else
        {:error,
         "Invalid .strings file: line #{line_num} is not a valid \"key\" = \"value\"; entry, comment, or empty line"}
      end
    end
  end
end
