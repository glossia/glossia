defmodule Glossia.Translations.Validate.Po do
  @moduledoc """
  Validates Gettext PO output. Ported from the CLI (`cli/src/validate/po.rs`):
  structural checks, a header entry, plural-forms consistency, format-string
  preservation vs the source, and an untranslated-entry check.
  """

  @format_regex ~r/%[sdfiu%]|%\([^)]+\)[sdfiu]|\{[0-9]+\}|\{[a-zA-Z_][a-zA-Z0-9_]*\}/

  def validate_po(content, source) do
    with :ok <- validate_structure(content) do
      entries = parse_entries(content)

      case Enum.find(entries, &(&1.msgid == "")) do
        nil ->
          {:error, ~s|po file missing header entry (msgid "" with Content-Type)|}

        header ->
          with :ok <- validate_plurals(entries, plural_count(header.msgstr)),
               :ok <- validate_format_strings(source, entries) do
            validate_untranslated(entries)
          end
      end
    end
  end

  defp validate_structure(content) do
    content
    |> lines()
    |> Enum.reduce_while({:ok, %{has_msgid: false, has_msgstr: false, state: ""}}, fn raw,
                                                                                      {:ok, s} ->
      line = String.trim(raw)

      cond do
        line == "" or String.starts_with?(line, "#") ->
          {:cont, {:ok, s}}

        String.starts_with?(line, "msgid ") ->
          if s.has_msgid and not s.has_msgstr do
            {:halt, {:error, "po entry missing msgstr"}}
          else
            check_quoted(line, "po msgid missing quoted string", %{
              s
              | has_msgid: true,
                has_msgstr: false,
                state: "msgid"
            })
          end

        String.starts_with?(line, "msgid_plural ") ->
          if s.state != "msgid" do
            {:halt, {:error, "po msgid_plural without msgid"}}
          else
            check_quoted(line, "po msgid_plural missing quoted string", s)
          end

        String.starts_with?(line, "msgstr") ->
          if not s.has_msgid do
            {:halt, {:error, "po msgstr without msgid"}}
          else
            check_quoted(line, "po msgstr missing quoted string", %{
              s
              | has_msgstr: true,
                state: "msgstr"
            })
          end

        String.starts_with?(line, "\"") ->
          if s.state == "" do
            {:halt, {:error, "po stray quoted string"}}
          else
            {:cont, {:ok, s}}
          end

        true ->
          {:halt, {:error, "po invalid line: #{line}"}}
      end
    end)
    |> case do
      {:ok, %{has_msgid: true, has_msgstr: false}} -> {:error, "po entry missing msgstr"}
      {:ok, _state} -> :ok
      {:error, _} = error -> error
    end
  end

  defp check_quoted(line, message, state) do
    if line |> String.graphemes() |> Enum.count(&(&1 == "\"")) >= 2 do
      {:cont, {:ok, state}}
    else
      {:halt, {:error, message}}
    end
  end

  defp validate_plurals(_entries, 0), do: :ok

  defp validate_plurals(entries, plural_count) do
    Enum.reduce_while(entries, :ok, fn entry, :ok ->
      if not entry.has_plural or entry.msgid == "" do
        {:cont, :ok}
      else
        forms =
          if map_size(entry.plural_msgstr) == 0,
            do: 0,
            else: Enum.max(Map.keys(entry.plural_msgstr)) + 1

        if forms == plural_count do
          {:cont, :ok}
        else
          {:halt,
           {:error,
            ~s|po plural forms mismatch: header declares nplurals=#{plural_count} but entry for "#{truncate(entry.msgid, 40)}" has #{forms} forms|}}
        end
      end
    end)
  end

  defp validate_format_strings(source, entries) do
    if String.trim(source) == "" do
      :ok
    else
      source
      |> parse_entries()
      |> Enum.reject(&(String.trim(&1.msgid) == ""))
      |> Enum.reduce_while(:ok, fn source_entry, :ok ->
        check_entry_format_strings(source_entry, entries)
      end)
    end
  end

  defp check_entry_format_strings(source_entry, entries) do
    with translated when not is_nil(translated) <-
           Enum.find(entries, &(&1.msgid == source_entry.msgid)),
         false <- String.trim(translated.msgstr) == "" do
      missing =
        @format_regex
        |> Regex.scan(source_entry.msgstr)
        |> Enum.map(&hd/1)
        |> Enum.find(&(not String.contains?(translated.msgstr, &1)))

      if missing do
        {:halt,
         {:error,
          ~s|po format string "#{missing}" in source msgstr for "#{truncate(source_entry.msgid, 40)}" missing from translation|}}
      else
        {:cont, :ok}
      end
    else
      _ -> {:cont, :ok}
    end
  end

  defp validate_untranslated(entries) do
    count =
      Enum.count(entries, fn e ->
        e.msgid == "" and e.msgstr == "" and map_size(e.plural_msgstr) == 0
      end)

    if count > 0, do: {:error, "po has #{count} untranslated entries"}, else: :ok
  end

  # ── parsing ────────────────────────────────────────────────────────────────

  defp parse_entries(content) do
    content
    |> lines()
    |> Enum.reduce(
      %{entries: [], current: new_entry(), state: "", plural_index: nil, in_entry: false},
      &parse_line/2
    )
    |> push_current()
    |> Map.fetch!(:entries)
    |> Enum.reverse()
  end

  defp parse_line(raw, acc) do
    line = String.trim(raw)

    cond do
      line == "" or String.starts_with?(line, "#") ->
        push_current(acc)

      String.starts_with?(line, "msgid ") ->
        acc = push_current(acc)

        %{
          acc
          | in_entry: true,
            state: "msgid",
            current: %{new_entry() | msgid: extract_quoted(line)}
        }

      String.starts_with?(line, "msgid_plural ") ->
        %{acc | state: "msgid_plural", current: %{acc.current | has_plural: true}}

      String.starts_with?(line, "msgstr[") ->
        index = plural_index(line)

        %{
          acc
          | state: "msgstr_plural",
            plural_index: index,
            current: %{
              acc.current
              | plural_msgstr: Map.put(acc.current.plural_msgstr, index, extract_quoted(line))
            }
        }

      String.starts_with?(line, "msgstr ") ->
        %{acc | state: "msgstr", current: %{acc.current | msgstr: extract_quoted(line)}}

      String.starts_with?(line, "\"") ->
        append_continuation(acc, extract_quoted_raw(line))

      true ->
        acc
    end
  end

  defp append_continuation(%{state: "msgid"} = acc, text),
    do: %{acc | current: %{acc.current | msgid: acc.current.msgid <> text}}

  defp append_continuation(%{state: "msgstr"} = acc, text),
    do: %{acc | current: %{acc.current | msgstr: acc.current.msgstr <> text}}

  defp append_continuation(%{state: "msgstr_plural", plural_index: index} = acc, text)
       when not is_nil(index) do
    case Map.fetch(acc.current.plural_msgstr, index) do
      {:ok, existing} ->
        %{
          acc
          | current: %{
              acc.current
              | plural_msgstr: Map.put(acc.current.plural_msgstr, index, existing <> text)
            }
        }

      :error ->
        acc
    end
  end

  defp append_continuation(acc, _text), do: acc

  defp push_current(%{in_entry: false} = acc), do: acc

  defp push_current(acc) do
    %{
      acc
      | entries: [acc.current | acc.entries],
        current: new_entry(),
        state: "",
        plural_index: nil,
        in_entry: false
    }
  end

  defp new_entry, do: %{msgid: "", msgstr: "", has_plural: false, plural_msgstr: %{}}

  defp plural_index(line) do
    with [_, inside] <- Regex.run(~r/^msgstr\[([^\]]*)\]/, line),
         {index, ""} <- Integer.parse(inside) do
      index
    else
      _ -> 0
    end
  end

  defp plural_count(header) do
    case Regex.run(~r/(?m)^Plural-Forms:\s*nplurals=(\d+);/, header) do
      [_, count] -> String.to_integer(count)
      _ -> 0
    end
  end

  defp extract_quoted(line) do
    case :binary.match(line, "\"") do
      {start, _len} -> extract_quoted_raw(binary_part(line, start, byte_size(line) - start))
      :nomatch -> ""
    end
  end

  defp extract_quoted_raw(line) do
    case Jason.decode(line) do
      {:ok, value} when is_binary(value) -> value
      _ -> ""
    end
  end

  defp truncate(input, max_len) do
    if String.length(input) <= max_len do
      input
    else
      String.slice(input, 0, max_len) <> "..."
    end
  end

  defp lines(content) do
    content |> String.split("\n") |> Enum.map(&String.trim_trailing(&1, "\r"))
  end
end
