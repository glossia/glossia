defmodule Glossia.Translations.Po do
  @moduledoc """
  Structural repairs a Gettext catalog needs that a model cannot be asked to make.

  A source template is English, so every plural entry reaches the model with two
  forms. A catalog for Japanese or Korean declares one. Collapsing the extra form
  is a mechanical consequence of the target language's plural rules rather than a
  translation decision, and a small model gets it wrong on nearly every entry,
  which fails `Glossia.Translations.Validate.Po` for the whole file after the
  usual retries. The engine does it here instead, deterministically.
  """

  @plural_forms_regex ~r/nplurals\s*=\s*(\d+)/

  @doc """
  Trims or pads every plural entry to the number of forms the catalog declares.

  The declared count wins over the locale's own count, so a catalog stays
  internally consistent with the header it carries. `locale` only supplies a
  count when the header has no `Plural-Forms`.
  """
  @spec normalize_plural_forms(String.t(), String.t() | nil) :: String.t()
  def normalize_plural_forms(content, locale) when is_binary(content) do
    case plural_count(content, locale) do
      nil -> content
      count -> content |> split_lines() |> rewrite_blocks(count) |> Enum.join("\n")
    end
  end

  defp plural_count(content, locale) do
    case Regex.run(@plural_forms_regex, content) do
      [_, declared] -> String.to_integer(declared)
      _ -> locale_plural_count(locale)
    end
  end

  defp locale_plural_count(nil), do: nil

  defp locale_plural_count(locale) do
    Gettext.Plural.nplurals(String.replace(locale, "-", "_"))
  rescue
    _ -> nil
  end

  # Keeping the original line endings out of the transformation means comments,
  # references and blank lines survive it untouched.
  defp split_lines(content), do: String.split(content, "\n")

  defp rewrite_blocks(lines, count) do
    lines
    |> Enum.chunk_by(&(String.trim(&1) == ""))
    |> Enum.flat_map(&rewrite_block(&1, count))
  end

  defp rewrite_block(block, count) do
    if Enum.any?(block, &plural_msgstr_line?/1) do
      block
      |> group_lines()
      |> apply_plural_count(count)
      |> Enum.flat_map(fn {_index, lines} -> lines end)
    else
      block
    end
  end

  # Each `msgstr[n]` owns the quoted continuation lines that follow it, so the
  # groups can be dropped or duplicated whole.
  defp group_lines(block) do
    block
    |> Enum.reduce([], fn line, groups ->
      cond do
        plural_msgstr_line?(line) -> [{plural_index(line), [line]} | groups]
        continuation?(line) and groups != [] -> prepend_to_head(groups, line)
        true -> [{nil, [line]} | groups]
      end
    end)
    |> Enum.reverse()
    |> Enum.map(fn {index, lines} -> {index, Enum.reverse(lines)} end)
  end

  defp prepend_to_head([{index, lines} | rest], line), do: [{index, [line | lines]} | rest]

  defp apply_plural_count(groups, count) do
    {plural_groups, other} = Enum.split_with(groups, fn {index, _lines} -> is_integer(index) end)

    kept =
      plural_groups
      |> Enum.filter(fn {index, _lines} -> index < count end)
      |> Enum.sort_by(fn {index, _lines} -> index end)

    padded = kept ++ padding(kept, count)

    merge_in_order(groups, other, padded)
  end

  defp padding([], _count), do: []

  defp padding(kept, count) do
    {_index, template} = List.last(kept)
    highest = kept |> List.last() |> elem(0)

    for index <- (highest + 1)..(count - 1)//1 do
      {index, Enum.map(template, &reindex(&1, index))}
    end
  end

  defp reindex(line, index) do
    if plural_msgstr_line?(line) do
      String.replace(line, ~r/msgstr\[\d+\]/, "msgstr[#{index}]", global: false)
    else
      line
    end
  end

  # The rebuilt plural run goes back where the first one was, so a trailing
  # comment or any other line in the block keeps its position.
  defp merge_in_order(groups, other, plural_groups) do
    first_plural = Enum.find_index(groups, fn {index, _lines} -> is_integer(index) end)
    before = Enum.take(other, count_before(groups, first_plural))

    before ++ plural_groups ++ Enum.drop(other, length(before))
  end

  defp count_before(groups, first_plural) do
    groups
    |> Enum.take(first_plural)
    |> Enum.count(fn {index, _lines} -> not is_integer(index) end)
  end

  defp plural_msgstr_line?(line), do: String.match?(line, ~r/^\s*msgstr\[\d+\]/)

  defp continuation?(line), do: String.match?(line, ~r/^\s*"/)

  defp plural_index(line) do
    [_, index] = Regex.run(~r/^\s*msgstr\[(\d+)\]/, line)
    String.to_integer(index)
  end
end
