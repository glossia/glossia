defmodule Glossia.Translations.Po do
  @moduledoc """
  Parse-and-rebuild pipeline for Gettext catalogs.

  Directly translating a `.po` source is unreliable: the model regularly
  emits invalid `.po` syntax, drops or reorders `msgid` entries, or loses
  plural forms. This module extracts the translatable strings from a source
  catalog, hands only the strings to the model, and rebuilds the catalog
  from the parsed source tree so the output is always syntactically valid
  and structurally identical to the source.

  Public API mirrors `Glossia.Translations.Markdown`:

    * `text_literals/1` returns the ordered list of translatable strings the
      catalog exposes, in the order the catalog visits them. The empty-msgid
      header entry is included as its own literal so the model can translate
      the "Language: xx" line and other header fields when relevant.

    * `rebuild_text_literals/2` re-parses the source and emits a fully valid
      `.po` file whose translatable strings have been replaced by the
      corresponding entries from the translated list.

  Comments (`# translator`, `#. extractor`, `#: references`, `#, flags`) and
  `msgctxt` are preserved verbatim. Obsolete entries (`#~` prefix) are kept
  in the output unchanged; their strings are never sent to the model.
  """

  # Parsed entry shape:
  #   %{
  #     comments: [String.t()],       # raw comment lines including `#` prefix
  #     obsolete: boolean(),
  #     msgctxt: String.t() | nil,
  #     msgid: String.t(),            # decoded
  #     msgid_plural: String.t() | nil,
  #     msgstr: String.t(),
  #     plural_msgstr: %{integer() => String.t()},
  #     header?: boolean()            # first entry with empty msgid + non-empty msgstr
  #   }

  @doc """
  Returns `{:ok, literals}` where `literals` is a flat list of the
  translatable strings in `source`, in emit order:

    * for the header entry (empty msgid), one literal for the msgstr;
    * for a regular entry, one literal for the msgstr;
    * for a plural entry, one literal per plural form's msgstr, indexed 0..N.

  `msgid` and `msgid_plural` are the SOURCE strings, not translated — they
  are treated as the message ID. The model is expected to translate the
  msgstrs into the target locale. When a source msgstr is empty, the msgid
  is used as the string to translate (the common case for a source catalog
  where translations have not been written yet).

  Returns `{:error, reason}` if the source cannot be parsed.
  """
  def text_literals(source) when is_binary(source) do
    entries = parse(source)
    literals = Enum.flat_map(entries, &entry_literals/1)
    {:ok, literals}
  end

  @doc """
  Re-parses `source` and returns `{:ok, output}` where `output` is a
  canonical `.po` file whose translatable strings have been replaced by
  the entries in `translated`, in the same order `text_literals/1` returned.

  Returns `{:error, reason}` when `translated`'s length does not match the
  number of literals in the source, or when the source cannot be parsed.
  """
  def rebuild_text_literals(source, translated) when is_binary(source) and is_list(translated) do
    entries = parse(source)
    expected = Enum.reduce(entries, 0, fn entry, acc -> acc + literals_count(entry) end)

    if length(translated) != expected do
      {:error,
       "po text-literal rebuild expected #{expected} strings but got #{length(translated)}"}
    else
      {rebuilt, []} =
        Enum.map_reduce(entries, translated, fn entry, remaining ->
          apply_translations(entry, remaining)
        end)

      {:ok, emit(rebuilt)}
    end
  end

  # ── parsing ────────────────────────────────────────────────────────────────

  defp parse(source) do
    source
    |> String.split("\n")
    |> parse_blocks([], new_block(), false)
    |> assign_header_flag()
  end

  defp new_block do
    %{
      comments: [],
      obsolete: false,
      msgctxt: nil,
      msgid: nil,
      msgid_plural: nil,
      msgstr: nil,
      plural_msgstr: %{},
      state: :comments,
      plural_index: nil
    }
  end

  defp parse_blocks([], entries, current, _in_entry?) do
    entries = push_block(current, entries)
    Enum.reverse(entries)
  end

  defp parse_blocks([line | rest], entries, current, in_entry?) do
    trimmed = String.trim(line)

    cond do
      trimmed == "" ->
        # blank line ends the current entry
        entries = push_block(current, entries)
        parse_blocks(rest, entries, new_block(), false)

      String.starts_with?(trimmed, "#~") ->
        # obsolete entry — collect all `#~` lines into one block
        current = %{current | obsolete: true}
        current = capture_obsolete_line(current, trimmed)
        parse_blocks(rest, entries, current, true)

      String.starts_with?(trimmed, "#") ->
        current = %{current | comments: [line | current.comments], state: :comments}
        parse_blocks(rest, entries, current, in_entry?)

      String.starts_with?(trimmed, "msgctxt ") ->
        entries = if in_entry?, do: push_block(current, entries), else: entries
        current = if in_entry?, do: new_block(), else: current
        current = %{current | msgctxt: decode_quoted(trimmed), state: :msgctxt}
        parse_blocks(rest, entries, current, true)

      String.starts_with?(trimmed, "msgid_plural ") ->
        current = %{current | msgid_plural: decode_quoted(trimmed), state: :msgid_plural}
        parse_blocks(rest, entries, current, true)

      String.starts_with?(trimmed, "msgid ") ->
        entries =
          if in_entry? and current.msgid != nil,
            do: push_block(current, entries),
            else: entries

        base = if in_entry? and current.msgid != nil, do: new_block(), else: current
        base = %{base | msgid: decode_quoted(trimmed), state: :msgid}
        parse_blocks(rest, entries, base, true)

      String.starts_with?(trimmed, "msgstr[") ->
        index = parse_plural_index(trimmed)
        value = decode_quoted(trimmed)

        current = %{
          current
          | plural_msgstr: Map.put(current.plural_msgstr, index, value),
            state: :msgstr_plural,
            plural_index: index
        }

        parse_blocks(rest, entries, current, true)

      String.starts_with?(trimmed, "msgstr ") ->
        current = %{current | msgstr: decode_quoted(trimmed), state: :msgstr}
        parse_blocks(rest, entries, current, true)

      String.starts_with?(trimmed, "\"") ->
        current = append_continuation(current, decode_quoted_raw(trimmed))
        parse_blocks(rest, entries, current, in_entry?)

      true ->
        parse_blocks(rest, entries, current, in_entry?)
    end
  end

  defp capture_obsolete_line(current, "#~" <> rest) do
    # store as a raw comment line so emit/1 can copy it back verbatim
    stripped = String.trim_leading(rest)
    %{current | comments: ["#~ " <> stripped | current.comments]}
  end

  defp append_continuation(%{state: :msgid} = block, text),
    do: %{block | msgid: (block.msgid || "") <> text}

  defp append_continuation(%{state: :msgid_plural} = block, text),
    do: %{block | msgid_plural: (block.msgid_plural || "") <> text}

  defp append_continuation(%{state: :msgctxt} = block, text),
    do: %{block | msgctxt: (block.msgctxt || "") <> text}

  defp append_continuation(%{state: :msgstr} = block, text),
    do: %{block | msgstr: (block.msgstr || "") <> text}

  defp append_continuation(%{state: :msgstr_plural, plural_index: idx} = block, text)
       when is_integer(idx) do
    existing = Map.get(block.plural_msgstr, idx, "")
    %{block | plural_msgstr: Map.put(block.plural_msgstr, idx, existing <> text)}
  end

  defp append_continuation(block, _text), do: block

  defp push_block(%{msgid: nil} = block, entries) do
    # No msgid seen. If we captured comments (e.g. a trailing `# translator`
    # block at end of file), preserve them as a comment-only block; otherwise
    # discard the empty block.
    if block.comments == [] and not block.obsolete do
      entries
    else
      entry = finalize(%{block | msgid: ""})
      [entry | entries]
    end
  end

  defp push_block(block, entries), do: [finalize(block) | entries]

  defp finalize(block) do
    %{
      comments: Enum.reverse(block.comments),
      obsolete: block.obsolete,
      msgctxt: block.msgctxt,
      msgid: block.msgid || "",
      msgid_plural: block.msgid_plural,
      msgstr: block.msgstr || "",
      plural_msgstr: block.plural_msgstr,
      header?: false
    }
  end

  # Mark the first (non-obsolete) entry with an empty msgid as the header.
  defp assign_header_flag(entries) do
    {marked, _found} =
      Enum.map_reduce(entries, false, fn entry, header_seen? ->
        if not header_seen? and not entry.obsolete and entry.msgid == "" do
          {%{entry | header?: true}, true}
        else
          {entry, header_seen?}
        end
      end)

    marked
  end

  defp parse_plural_index(line) do
    case Regex.run(~r/^msgstr\[(\d+)\]/, line) do
      [_, n] -> String.to_integer(n)
      _ -> 0
    end
  end

  defp decode_quoted(line) do
    case :binary.match(line, "\"") do
      {start, _} ->
        line
        |> binary_part(start, byte_size(line) - start)
        |> decode_quoted_raw()

      :nomatch ->
        ""
    end
  end

  defp decode_quoted_raw(line) do
    trimmed = String.trim(line)

    with true <- String.starts_with?(trimmed, "\""),
         last = String.length(trimmed) - 1,
         "\"" <> _ = trailing <- String.slice(trimmed, last..last),
         _ = trailing,
         {:ok, value} <- JSON.decode(trimmed),
         true <- is_binary(value) do
      value
    else
      _ -> ""
    end
  end

  # ── literals ──────────────────────────────────────────────────────────────

  # Returns the list of translatable strings this entry exposes, in emit
  # order. Obsolete entries are never sent to the model.
  defp entry_literals(%{obsolete: true}), do: []

  defp entry_literals(%{header?: true, msgstr: msgstr}), do: [msgstr]

  defp entry_literals(%{msgid_plural: nil, msgid: msgid, msgstr: msgstr}) do
    [source_for_translation(msgid, msgstr)]
  end

  defp entry_literals(%{msgid: msgid, msgid_plural: msgid_plural, plural_msgstr: plurals}) do
    # Emit one literal per plural form in ascending order (0, 1, 2, ...).
    # The source is msgid for form 0 and msgid_plural for other forms; if the
    # source msgstr for that form is already filled, use it as the source of
    # translation (mirrors the singular case).
    max_idx = plurals |> Map.keys() |> Enum.max(fn -> 1 end)
    upper = max(max_idx, 1)

    for idx <- 0..upper do
      base = if idx == 0, do: msgid, else: msgid_plural
      current = Map.get(plurals, idx, "")
      source_for_translation(base, current)
    end
  end

  defp literals_count(%{obsolete: true}), do: 0
  defp literals_count(%{header?: true}), do: 1
  defp literals_count(%{msgid_plural: nil}), do: 1

  defp literals_count(%{plural_msgstr: plurals}) do
    max_idx = plurals |> Map.keys() |> Enum.max(fn -> 1 end)
    max(max_idx, 1) + 1
  end

  # If the source catalog already has a non-empty msgstr, translate that
  # (developer wrote a source-language string in msgstr). Otherwise translate
  # the msgid itself, which is the common case for a template catalog whose
  # translations have not been written yet.
  defp source_for_translation(_msgid, msgstr) when is_binary(msgstr) and msgstr != "",
    do: msgstr

  defp source_for_translation(msgid, _msgstr), do: msgid

  # ── rebuild ────────────────────────────────────────────────────────────────

  defp apply_translations(%{obsolete: true} = entry, remaining), do: {entry, remaining}

  defp apply_translations(%{header?: true} = entry, [translated | rest]) do
    {%{entry | msgstr: translated}, rest}
  end

  defp apply_translations(%{msgid_plural: nil} = entry, [translated | rest]) do
    {%{entry | msgstr: translated}, rest}
  end

  defp apply_translations(entry, remaining) do
    count = literals_count(entry)
    {take, rest} = Enum.split(remaining, count)

    plural_msgstr =
      take
      |> Enum.with_index()
      |> Enum.into(%{}, fn {value, idx} -> {idx, value} end)

    {%{entry | plural_msgstr: plural_msgstr, msgstr: ""}, rest}
  end

  # ── emit ──────────────────────────────────────────────────────────────────

  defp emit(entries) do
    entries
    |> Enum.map(&emit_entry/1)
    |> Enum.join("\n")
    |> ensure_trailing_newline()
  end

  defp ensure_trailing_newline(str) do
    if String.ends_with?(str, "\n"), do: str, else: str <> "\n"
  end

  defp emit_entry(%{obsolete: true, comments: comments}) do
    # obsolete lines are stored as `#~ ...` in `comments` already
    Enum.join(comments, "\n") <> "\n"
  end

  defp emit_entry(entry) do
    lines =
      Enum.concat([
        entry.comments,
        maybe_emit(entry.msgctxt, "msgctxt"),
        emit_quoted("msgid", entry.msgid),
        maybe_emit(entry.msgid_plural, "msgid_plural"),
        emit_msgstrs(entry)
      ])

    Enum.join(lines, "\n") <> "\n"
  end

  defp maybe_emit(nil, _keyword), do: []
  defp maybe_emit(value, keyword), do: emit_quoted(keyword, value)

  defp emit_msgstrs(%{msgid_plural: nil, msgstr: msgstr}), do: emit_quoted("msgstr", msgstr)

  defp emit_msgstrs(%{plural_msgstr: plurals}) do
    plurals
    |> Map.keys()
    |> Enum.sort()
    |> Enum.flat_map(fn idx ->
      emit_quoted("msgstr[#{idx}]", Map.get(plurals, idx, ""))
    end)
  end

  # Emit a `keyword "value"` line (single-line quoted form). Uses JSON encoding
  # to escape quotes, backslashes, and newlines the way `.po` expects
  # (JSON.encode! produces valid PO-quoted string form for standard escapes).
  defp emit_quoted(keyword, value) when is_binary(value) do
    [~s(#{keyword} #{JSON.encode!(value)})]
  end
end
