defmodule GlossiaAgent.Checks.Syntax do
  @moduledoc """
  Syntax validation for translated output.
  Validates JSON, YAML, PO, and markdown frontmatter.
  """

  @doc "Validate the syntax of translated output. Returns nil if valid, error string otherwise."
  @spec validate(GlossiaAgent.Format.t(), String.t(), String.t()) :: String.t() | nil
  def validate(:json, output, _source) do
    case Jason.decode(output) do
      {:ok, _} -> nil
      {:error, error} -> Exception.message(error)
    end
  end

  def validate(:yaml, output, _source) do
    case YamlElixir.read_from_string(output) do
      {:ok, _} -> nil
      {:error, error} -> Exception.message(error)
    end
  end

  def validate(:po, output, source), do: validate_po_thorough(output, source)
  def validate(:markdown, output, _source), do: validate_markdown(output)
  def validate(:text, _output, _source), do: nil
  def validate(_, _output, _source), do: nil

  # -- Markdown ----------------------------------------------------------------

  defp validate_markdown(content) do
    lines = String.split(content, "\n")

    case lines do
      [] ->
        nil

      [first | rest] ->
        marker = String.trim(first)

        if marker not in ["---", "+++"] do
          nil
        else
          end_idx = Enum.find_index(rest, &(String.trim(&1) == marker))

          if end_idx == nil do
            "markdown frontmatter missing closing #{marker}"
          else
            frontmatter = rest |> Enum.take(end_idx) |> Enum.join("\n")

            if marker == "---" do
              case YamlElixir.read_from_string(frontmatter) do
                {:ok, _} -> nil
                {:error, e} -> "markdown frontmatter invalid yaml: #{Exception.message(e)}"
              end
            else
              case Toml.decode(frontmatter) do
                {:ok, _} -> nil
                {:error, e} -> "markdown frontmatter invalid toml: #{inspect(e)}"
              end
            end
          end
        end
    end
  end

  # -- PO validation -----------------------------------------------------------

  @doc false
  def validate_po(content) do
    lines = String.split(content, "\n")
    do_validate_po(lines, "", false, false)
  end

  defp do_validate_po([], _state, has_msgid, has_msgstr) do
    if has_msgid && !has_msgstr, do: "po entry missing msgstr", else: nil
  end

  defp do_validate_po([raw_line | rest], state, has_msgid, has_msgstr) do
    line = String.trim(raw_line)

    cond do
      line == "" || String.starts_with?(line, "#") ->
        do_validate_po(rest, state, has_msgid, has_msgstr)

      String.starts_with?(line, "msgid ") ->
        if has_msgid && !has_msgstr do
          "po entry missing msgstr"
        else
          if !has_quoted_string?(line),
            do: "po msgid missing quoted string",
            else: do_validate_po(rest, "msgid", true, false)
        end

      String.starts_with?(line, "msgid_plural ") ->
        if state != "msgid" do
          "po msgid_plural without msgid"
        else
          if !has_quoted_string?(line),
            do: "po msgid_plural missing quoted string",
            else: do_validate_po(rest, state, has_msgid, has_msgstr)
        end

      String.starts_with?(line, "msgstr") ->
        if !has_msgid do
          "po msgstr without msgid"
        else
          if !has_quoted_string?(line),
            do: "po msgstr missing quoted string",
            else: do_validate_po(rest, "msgstr", has_msgid, true)
        end

      String.starts_with?(line, "\"") ->
        if state == "",
          do: "po stray quoted string",
          else: do_validate_po(rest, state, has_msgid, has_msgstr)

      true ->
        "po invalid line: #{line}"
    end
  end

  defp validate_po_thorough(content, source) do
    base_err = validate_po(content)
    if base_err, do: base_err, else: do_validate_po_thorough(content, source)
  end

  defp do_validate_po_thorough(content, source) do
    entries = parse_po_entries(content)

    has_header = Enum.any?(entries, fn e -> e.msgid == "" && e.msgstr != "" end)

    if !has_header && entries != [] do
      "po file missing header entry (msgid \"\" with Content-Type)"
    else
      header_entry = Enum.find(entries, fn e -> e.msgid == "" end)
      plural_count = if header_entry, do: extract_plural_forms_count(header_entry.msgstr), else: 0

      plural_err =
        if plural_count > 0 do
          check_plural_forms(entries, plural_count)
        end

      if plural_err do
        plural_err
      else
        format_err =
          if String.trim(source) != "" do
            check_format_strings(entries, parse_po_entries(source))
          end

        if format_err do
          format_err
        else
          untranslated =
            Enum.count(entries, fn e ->
              e.msgid == "" && e.msgstr == "" && e.plural_msgstrs == %{}
            end)

          if untranslated > 0, do: "po has #{untranslated} untranslated entries"
        end
      end
    end
  end

  defp check_plural_forms(entries, plural_count) do
    Enum.find_value(entries, fn entry ->
      if !entry.has_plural || entry.msgid == "" do
        nil
      else
        max_plural =
          entry.plural_msgstrs
          |> Map.keys()
          |> Enum.max(fn -> -1 end)

        if max_plural + 1 != plural_count do
          msgid_short = String.slice(entry.msgid, 0, 40)

          "po plural forms mismatch: header declares nplurals=#{plural_count} but entry for \"#{msgid_short}\" has #{max_plural + 1} forms"
        end
      end
    end)
  end

  defp check_format_strings(entries, source_entries) do
    format_re = ~r/%[sdfiu%]|%\([^)]+\)[sdfiu]|\{[0-9]+\}|\{[a-zA-Z_][a-zA-Z0-9_]*\}/

    Enum.find_value(source_entries, fn src_entry ->
      if String.trim(src_entry.msgid) == "" do
        nil
      else
        translated = Enum.find(entries, fn e -> e.msgid == src_entry.msgid end)

        if translated == nil || String.trim(translated.msgstr) == "" do
          nil
        else
          src_formats = Regex.scan(format_re, src_entry.msgstr) |> Enum.map(&hd/1)

          Enum.find_value(src_formats, fn fmt_str ->
            if !String.contains?(translated.msgstr, fmt_str) do
              msgid_short = String.slice(src_entry.msgid, 0, 40)

              "po format string \"#{fmt_str}\" in source msgstr for \"#{msgid_short}\" missing from translation"
            end
          end)
        end
      end
    end)
  end

  # -- PO parsing --------------------------------------------------------------

  defmodule PoEntry do
    @moduledoc false
    defstruct msgid: "", msgstr: "", has_plural: false, plural_msgstrs: %{}
  end

  defp parse_po_entries(content) do
    lines = String.split(content, "\n")

    {entries, current} =
      Enum.reduce(
        lines,
        {[],
         %{
           msgid: "",
           msgstr: "",
           has_plural: false,
           plural_msgstrs: %{},
           state: "",
           plural_index: nil,
           in_entry: false
         }},
        fn raw_line, {entries, current} ->
          line = String.trim(raw_line)

          cond do
            line == "" || String.starts_with?(line, "#") ->
              if current.in_entry do
                entry = %PoEntry{
                  msgid: current.msgid,
                  msgstr: current.msgstr,
                  has_plural: current.has_plural,
                  plural_msgstrs: current.plural_msgstrs
                }

                {[entry | entries],
                 %{
                   msgid: "",
                   msgstr: "",
                   has_plural: false,
                   plural_msgstrs: %{},
                   state: "",
                   plural_index: nil,
                   in_entry: false
                 }}
              else
                {entries, current}
              end

            String.starts_with?(line, "msgid ") ->
              if current.in_entry do
                entry = %PoEntry{
                  msgid: current.msgid,
                  msgstr: current.msgstr,
                  has_plural: current.has_plural,
                  plural_msgstrs: current.plural_msgstrs
                }

                {[entry | entries],
                 %{
                   msgid: extract_quoted(line),
                   msgstr: "",
                   has_plural: false,
                   plural_msgstrs: %{},
                   state: "msgid",
                   plural_index: nil,
                   in_entry: true
                 }}
              else
                {entries,
                 %{current | msgid: extract_quoted(line), state: "msgid", in_entry: true}}
              end

            String.starts_with?(line, "msgid_plural ") ->
              {entries, %{current | has_plural: true, state: "msgid_plural"}}

            String.starts_with?(line, "msgstr[") ->
              idx = extract_plural_index(line)
              quoted = extract_quoted(line)

              {entries,
               %{
                 current
                 | state: "msgstr_plural",
                   plural_index: idx,
                   plural_msgstrs: Map.put(current.plural_msgstrs, idx, quoted)
               }}

            String.starts_with?(line, "msgstr ") ->
              {entries, %{current | state: "msgstr", msgstr: extract_quoted(line)}}

            String.starts_with?(line, "\"") ->
              cont = extract_quoted_raw(line)

              current =
                case current.state do
                  "msgid" ->
                    %{current | msgid: current.msgid <> cont}

                  "msgstr" ->
                    %{current | msgstr: current.msgstr <> cont}

                  "msgstr_plural" when current.plural_index != nil ->
                    existing = Map.get(current.plural_msgstrs, current.plural_index, "")

                    %{
                      current
                      | plural_msgstrs:
                          Map.put(current.plural_msgstrs, current.plural_index, existing <> cont)
                    }

                  _ ->
                    current
                end

              {entries, current}

            true ->
              {entries, current}
          end
        end
      )

    # Push final entry
    entries =
      if current.in_entry do
        [
          %PoEntry{
            msgid: current.msgid,
            msgstr: current.msgstr,
            has_plural: current.has_plural,
            plural_msgstrs: current.plural_msgstrs
          }
          | entries
        ]
      else
        entries
      end

    Enum.reverse(entries)
  end

  defp has_quoted_string?(line) do
    count =
      line
      |> String.graphemes()
      |> Enum.reduce({0, false}, fn ch, {count, escaped} ->
        cond do
          ch == "\\" && !escaped -> {count, true}
          ch == "\"" && !escaped -> {count + 1, false}
          true -> {count, false}
        end
      end)
      |> elem(0)

    count >= 2
  end

  defp extract_quoted(line) do
    case :binary.match(line, "\"") do
      {pos, _} -> extract_quoted_raw(binary_part(line, pos, byte_size(line) - pos))
      :nomatch -> ""
    end
  end

  defp extract_quoted_raw(line) do
    trimmed = String.trim(line)

    if String.length(trimmed) < 2 || !String.starts_with?(trimmed, "\"") ||
         !String.ends_with?(trimmed, "\"") do
      ""
    else
      trimmed
      |> String.slice(1..-2//1)
      |> String.replace("\\n", "\n")
      |> String.replace("\\t", "\t")
      |> String.replace("\\\"", "\"")
      |> String.replace("\\\\", "\\")
    end
  end

  defp extract_plural_index(line) do
    case Regex.run(~r/msgstr\[(\d+)\]/, line) do
      [_, idx] -> String.to_integer(idx)
      _ -> 0
    end
  end

  defp extract_plural_forms_count(header) do
    all_lines = String.split(header, "\\n") ++ String.split(header, "\n")

    Enum.find_value(all_lines, 0, fn line ->
      normalized = line |> String.trim() |> String.downcase()

      if String.starts_with?(normalized, "plural-forms:") do
        case Regex.run(~r/nplurals=(\d+)/, normalized) do
          [_, n] -> String.to_integer(n)
          _ -> nil
        end
      end
    end)
  end
end
