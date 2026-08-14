defmodule Glossia.Translations.Prompt do
  @moduledoc """
  Builds the system and user prompts for content translation.

  This is the translation "moat": the proprietary prompt logic that used to live
  in the Rust CLI (`cli/src/translate/prompt.rs`). It now runs server-side so it
  is never shipped to clients — the CLI sends source content and receives
  translations, without ever seeing how the prompt is constructed.

  Keep this in sync with the formats understood by the CLI planner. Supported
  formats: `"markdown"`, `"json"`, `"yaml"`, `"po"`, `"text"`.
  """

  @structured_formats ~w(json yaml po)
  @version 2

  @doc """
  Version of the prompt contract used in translation lockfiles.

  Increment this when prompt behavior changes in a way that should make existing
  translations stale.
  """
  def version, do: @version

  @doc """
  Builds the system prompt for a translation request.

  Expects a map with:

    * `:format` - `"markdown" | "json" | "yaml" | "po" | "text"`
    * `:source_language`, `:language`, `:locale` - display strings
    * `:context_body`, `:locale_override_body` - optional project/locale guidance
    * `:server_context_body` - resolved voice and source-relevant terminology
    * `:frontmatter_preserved` - whether frontmatter is re-attached client-side
    * `:custom_prompt` - optional per-document instructions
  """
  def build_system_prompt(%{format: "po"} = input), do: po_prompt(input)

  def build_system_prompt(input) do
    format = input.format

    lines = [
      "You are a professional localization engine.",
      "Translate the content from #{input.source_language} to #{input.language} (#{input.locale}).",
      "Preserve code blocks, inline code, URLs, placeholders, lists, and headings.",
      "Copy every Glossia protected token marker byte-for-byte exactly once.",
      "Return only the translated content. Do not add commentary or markdown fences."
    ]

    lines =
      if structured?(format) do
        lines ++ ["Return valid #{format} only. Do not wrap the output in markdown fences."]
      else
        lines
      end

    lines =
      if Map.get(input, :frontmatter_preserved, false) do
        lines ++ ["Frontmatter is preserved separately. Do not add new frontmatter."]
      else
        lines
      end

    lines =
      if Map.get(input, :segment_count, 1) > 1 do
        lines ++
          [
            "The document is translated in segments. Return only the complete translation of the supplied segment."
          ]
      else
        lines
      end

    lines =
      case trimmed(Map.get(input, :custom_prompt)) do
        "" -> lines
        value -> lines ++ [value]
      end

    lines
    |> append_block("Project context:", Map.get(input, :context_body))
    |> append_block(
      "Locale-specific instructions for #{input.language}:",
      Map.get(input, :locale_override_body)
    )
    |> append_block(
      "Organization context for #{input.language}:",
      Map.get(input, :server_context_body)
    )
    |> Enum.join("\n")
  end

  @doc """
  Builds the user prompt carrying the source content, optionally appending the
  previous validation error so the model can self-correct on a retry.
  """
  def build_user_prompt(
        source_language,
        locale,
        language,
        source_content,
        last_error \\ nil,
        segment \\ %{}
      ) do
    segment_kind = Map.get(segment, :kind, "content")
    segment_index = Map.get(segment, :index, 1)
    segment_count = Map.get(segment, :count, 1)

    instruction =
      cond do
        segment_kind == "frontmatter" ->
          "Translate only the human-readable string values in this frontmatter from #{source_language} to #{language} (#{locale}). Preserve its syntax, keys, identifiers, dates, and delimiters exactly."

        segment_count > 1 ->
          "Translate segment #{segment_index} of #{segment_count} from #{source_language} to #{language} (#{locale}). Return only this segment."

        true ->
          "Translate the following content from #{source_language} to #{language} (#{locale})."
      end

    parts = [
      instruction,
      "",
      source_content
    ]

    parts =
      if present?(last_error) do
        parts ++
          [
            "",
            "The reassembled document previously failed validation: #{last_error}\nReturn a corrected translation of only this supplied segment. Preserve every required token present in this segment."
          ]
      else
        parts
      end

    Enum.join(parts, "\n")
  end

  defp po_prompt(input) do
    plural_forms = plural_forms(input.locale)

    lines =
      if Map.get(input, :segment_count, 1) > 1 do
        segmented_po_prompt(input, plural_forms)
      else
        atomic_po_prompt(input, plural_forms)
      end

    lines
    |> append_block("Project context:", Map.get(input, :context_body))
    |> append_block(
      "Locale-specific instructions for #{input.language}:",
      Map.get(input, :locale_override_body)
    )
    |> append_block(
      "Organization context for #{input.language}:",
      Map.get(input, :server_context_body)
    )
    |> Enum.join("\n")
  end

  defp atomic_po_prompt(input, plural_forms) do
    [
      "You are a professional translator specializing in software localization.",
      "You translate Gettext PO template files from #{input.source_language} to #{input.language} (#{input.locale}).",
      "Output ONLY a valid Gettext .po file. No markdown fences, no explanation, no preamble.",
      "",
      "Rules:",
      "1. The first entry must be the PO header.",
      "2. The header must include Language: #{input.locale}.",
      "3. The header must include MIME-Version: 1.0, Content-Type: text/plain; charset=UTF-8, and Content-Transfer-Encoding: 8bit.",
      "4. The header must include Plural-Forms: #{plural_forms}.",
      "5. Preserve all msgid values exactly as they appear in the source.",
      "6. Translate each msgid into the corresponding msgstr for #{input.language}.",
      "7. Preserve all interpolation variables, HTML tags, and comments exactly as-is.",
      "8. For plural forms, provide the correct number of msgstr[N] entries for #{input.language}.",
      "9. Do not add the fuzzy flag to any translations.",
      "10. Keep each msgstr on a single line unless the source already uses multi-line PO strings."
    ]
  end

  defp segmented_po_prompt(input, plural_forms) do
    header_rules =
      if input.segment_index == 1 do
        [
          "9. This segment contains the PO header. Keep it as the first entry.",
          "10. The header must include Language: #{input.locale}.",
          "11. The header must include MIME-Version: 1.0, Content-Type: text/plain; charset=UTF-8, and Content-Transfer-Encoding: 8bit.",
          "12. The header must include Plural-Forms: #{plural_forms}."
        ]
      else
        ["9. Do not add a PO header because it belongs only in the first segment."]
      end

    [
      "You are a professional translator specializing in software localization.",
      "You translate segment #{input.segment_index} of #{input.segment_count} from a Gettext PO template from #{input.source_language} to #{input.language} (#{input.locale}).",
      "Output ONLY valid Gettext PO entries for the supplied segment. No markdown fences, no explanation, no preamble.",
      "",
      "Rules:",
      "1. Preserve every supplied entry and its order. Do not add, omit, or duplicate entries.",
      "2. Preserve all msgid values exactly as they appear in the source.",
      "3. Translate each msgid into the corresponding msgstr for #{input.language}.",
      "4. Preserve all references, flags, interpolation variables, HTML tags, and comments exactly as-is.",
      "5. For plural forms, provide the correct number of msgstr[N] entries for #{input.language}.",
      "6. Use the locale plural rule #{plural_forms}.",
      "7. Do not add the fuzzy flag to any translations.",
      "8. Keep each msgstr on a single line unless the source already uses multi-line PO strings."
      | header_rules
    ]
  end

  defp plural_forms("es"), do: "nplurals=2; plural=n != 1;"

  defp plural_forms(locale) when locale in ~w(ja ko yue_Hant zh_Hans zh_Hant),
    do: "nplurals=1; plural=0;"

  defp plural_forms("ru"),
    do:
      "nplurals=3; plural=n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2;"

  defp plural_forms(_locale), do: "nplurals=2; plural=n != 1;"

  defp append_block(lines, header, body) do
    case trimmed(body) do
      "" -> lines
      value -> lines ++ ["", header, value]
    end
  end

  defp structured?(format), do: format in @structured_formats

  defp present?(value), do: trimmed(value) != ""

  defp trimmed(nil), do: ""
  defp trimmed(value) when is_binary(value), do: String.trim(value)
  defp trimmed(_value), do: ""
end
