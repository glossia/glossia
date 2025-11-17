defmodule Glossia.Formats.XliffHandler do
  @moduledoc """
  Handles XLIFF (XML Localization Interchange File Format) files.

  This handler validates XLIFF syntax and translates content using AI
  with format-aware instructions.
  """

  @behaviour Glossia.Formats.Handler

  alias Glossia.AI.Translator
  alias SweetXml

  @format_instructions """
  This is an XLIFF (XML Localization Interchange File Format) file. You MUST:
  - Preserve ALL <source> elements exactly as they are
  - Preserve ALL XML structure, tags, and attributes
  - Preserve ALL formatting, indentation, and line structure
  - Translate ONLY the content inside <target> elements
  - Keep all empty <target></target> elements empty if they were empty
  - Maintain the exact same XML structure and namespaces

  The output MUST be valid XLIFF/XML with the exact same structure as the input.
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
    try do
      SweetXml.parse(content, dtd: :none)
      :ok
    rescue
      _ -> {:error, "Invalid XLIFF: not valid XML"}
    end
  end
end
