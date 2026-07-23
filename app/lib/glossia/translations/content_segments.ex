defmodule Glossia.Translations.ContentSegments do
  @moduledoc """
  Splits long prose into translation-sized segments.

  Segments are packed from paragraph boundaries. Callers can provide paired
  line-prefix delimiters for blocks that must remain intact, such as fenced
  source code. Short content remains a single segment.
  """

  @max_segment_bytes 4_000

  @doc """
  Returns non-empty segments whose boundaries fall between prose blocks.

  Options:

    * `:max_segment_bytes` - target maximum size for packed segments
    * `:protected_delimiters` - line prefixes that toggle an indivisible block
  """
  def split(content, opts \\ [])

  def split("", _opts), do: []

  def split(content, opts) when is_binary(content) and is_list(opts) do
    max_segment_bytes = Keyword.get(opts, :max_segment_bytes, @max_segment_bytes)
    protected_delimiters = Keyword.get(opts, :protected_delimiters, [])

    if not (is_integer(max_segment_bytes) and max_segment_bytes > 0) do
      raise ArgumentError, ":max_segment_bytes must be a positive integer"
    end

    content
    |> block_units(protected_delimiters)
    |> pack(max_segment_bytes)
  end

  defp block_units(content, protected_delimiters) do
    content
    |> lines_with_endings()
    |> Enum.reduce({[], "", nil}, fn line, acc ->
      accumulate_line(line, acc, protected_delimiters)
    end)
    |> then(fn {units, current, _fence} -> flush_unit(units, current) end)
    |> Enum.reverse()
  end

  defp accumulate_line(line, {units, current, delimiter}, protected_delimiters) do
    trimmed = String.trim(line)
    current = current <> line
    next_delimiter = toggle_delimiter(delimiter, trimmed, protected_delimiters)

    if is_nil(next_delimiter) and trimmed == "" do
      {flushed, ""} = flush_current(units, current)
      {flushed, "", next_delimiter}
    else
      {units, current, next_delimiter}
    end
  end

  defp flush_current(units, ""), do: {units, ""}
  defp flush_current(units, current), do: {[current | units], ""}

  defp flush_unit(units, ""), do: units
  defp flush_unit(units, current), do: [current | units]

  defp toggle_delimiter(nil, line, protected_delimiters) do
    Enum.find(protected_delimiters, &String.starts_with?(line, &1))
  end

  defp toggle_delimiter(delimiter, line, _protected_delimiters) do
    if String.starts_with?(line, delimiter), do: nil, else: delimiter
  end

  defp lines_with_endings(content) do
    parts = String.split(content, "\n", trim: false)
    last_index = length(parts) - 1

    parts
    |> Enum.with_index()
    |> Enum.map(fn {line, index} -> if index < last_index, do: line <> "\n", else: line end)
  end

  defp pack(units, max_segment_bytes) do
    units
    |> Enum.reduce({[], ""}, fn unit, {segments, current} ->
      cond do
        current == "" ->
          {segments, unit}

        byte_size(current) + byte_size(unit) <= max_segment_bytes ->
          {segments, current <> unit}

        true ->
          {[String.trim(current) | segments], unit}
      end
    end)
    |> then(fn {segments, current} ->
      segments =
        if String.trim(current) == "", do: segments, else: [String.trim(current) | segments]

      Enum.reverse(segments)
    end)
  end
end
