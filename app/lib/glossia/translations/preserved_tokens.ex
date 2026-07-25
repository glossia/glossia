defmodule Glossia.Translations.PreservedTokens do
  @moduledoc """
  Masks content that must survive translation and restores it afterwards.

  The masker deliberately recognizes a small, format-neutral set of atomic
  values rather than attempting to parse every Markdown extension. Fenced code,
  inline code, URLs, and placeholders are replaced with stable markers before a
  model sees the content. The exact source values are then reconstructed in the
  translated output.
  """

  @default_kinds ~w(code_blocks inline_code urls placeholders)
  @version 2
  @inline_code_regex ~r/`[^`\n]+`/
  @url_regex ~r/https?:\/\/[^\s\)"'<>]+/
  @placeholder_regex ~r/\{\{[^{}\n]+\}\}|\{[^\s{}]+\}/

  @type protection :: %{
          text: String.t(),
          replacements: [{String.t(), String.t()}]
        }

  @doc "Version of token preservation behavior used by translation locks."
  def version, do: @version

  @doc "Resolves the configured preservation kinds."
  def resolve([]), do: @default_kinds

  def resolve(kinds) do
    if Enum.any?(kinds, &(String.downcase(String.trim(&1)) == "none")) do
      []
    else
      kinds
      |> Enum.map(&String.downcase(String.trim(&1)))
      |> Enum.reject(&(&1 == ""))
    end
  end

  @doc "Returns the exact source values recognized for the requested kinds."
  def values(source, kinds) when is_binary(source) and is_list(kinds) do
    source
    |> ranges(kinds)
    |> Enum.map(& &1.value)
  end

  @doc "Replaces recognized source values with collision-resistant markers."
  @spec protect(String.t(), [String.t()]) :: protection()
  def protect(source, kinds) when is_binary(source) and is_list(kinds) do
    ranges = ranges(source, kinds)

    if ranges == [] do
      %{text: source, replacements: []}
    else
      marker_roots = marker_roots(source)

      {parts, cursor, replacements} =
        ranges
        |> Enum.with_index()
        |> Enum.reduce({[], 0, []}, fn {range, index}, {parts, cursor, replacements} ->
          marker = marker(range.kind, marker_roots, index)
          prefix = binary_part(source, cursor, range.start - cursor)

          {
            [marker, prefix | parts],
            range.start + range.length,
            [{marker, range.value} | replacements]
          }
        end)

      tail = binary_part(source, cursor, byte_size(source) - cursor)

      %{
        text: IO.iodata_to_binary(Enum.reverse([tail | parts])),
        replacements: Enum.reverse(replacements)
      }
    end
  end

  @doc "Restores protected values, failing when a model changed or duplicated a marker."
  @spec restore(String.t(), protection()) :: {:ok, String.t()} | {:error, String.t()}
  def restore(output, %{replacements: replacements}) when is_binary(output) do
    case Enum.find(replacements, fn {marker, _value} ->
           length(:binary.matches(output, marker)) != 1
         end) do
      nil ->
        restored =
          Enum.reduce(replacements, output, fn {marker, value}, text ->
            String.replace(text, marker, value)
          end)

        {:ok, restored}

      {marker, value} ->
        count = length(:binary.matches(output, marker))

        {:error,
         "protected token marker occurred #{count} times; preserve it exactly once for #{inspect(value)}"}
    end
  end

  defp ranges(source, kinds) do
    code_ranges =
      if "code_blocks" in kinds do
        fenced_code_ranges(source)
      else
        []
      end

    [
      {"inline_code", @inline_code_regex},
      {"urls", @url_regex},
      {"placeholders", @placeholder_regex}
    ]
    |> Enum.reduce(code_ranges, fn {kind, regex}, accepted ->
      if kind in kinds do
        regex_ranges(source, regex, kind)
        |> Enum.reduce(accepted, fn candidate, ranges ->
          if Enum.any?(ranges, &overlap?(&1, candidate)), do: ranges, else: [candidate | ranges]
        end)
      else
        accepted
      end
    end)
    |> Enum.sort_by(& &1.start)
  end

  defp regex_ranges(source, regex, kind) do
    regex
    |> Regex.scan(source, return: :index, capture: :first)
    |> Enum.map(fn [{start, length}] ->
      %{start: start, length: length, value: binary_part(source, start, length), kind: kind}
    end)
  end

  defp fenced_code_ranges(source) do
    source
    |> lines_with_offsets()
    |> Enum.reduce({[], nil}, fn {line, start}, {ranges, open} ->
      case open do
        nil ->
          case opening_fence(line) do
            nil -> {ranges, nil}
            fence -> {ranges, %{start: start, fence: fence}}
          end

        %{start: block_start, fence: fence} = current ->
          if closing_fence?(line, fence) do
            length = start + byte_size(line) - block_start
            value = binary_part(source, block_start, length)

            {[
               %{start: block_start, length: length, value: value, kind: "code_blocks"} | ranges
             ], nil}
          else
            {ranges, current}
          end
      end
    end)
    |> elem(0)
  end

  defp opening_fence(line) do
    case Regex.run(~r/^[ \t]{0,3}(`{3,}|~{3,})/, line, capture: :all_but_first) do
      [fence] -> fence
      _ -> nil
    end
  end

  defp closing_fence?(line, opening) do
    case Regex.run(
           ~r/^[ \t]{0,3}(`+|~+)[ \t]*(?:\r?\n)?$/,
           line,
           capture: :all_but_first
         ) do
      [closing] ->
        String.first(closing) == String.first(opening) and
          String.length(closing) >= String.length(opening)

      _ ->
        false
    end
  end

  defp lines_with_offsets(source) do
    parts = String.split(source, "\n", trim: false)
    last_index = length(parts) - 1

    parts
    |> Enum.with_index()
    |> Enum.map_reduce(0, fn {line, index}, offset ->
      line = if index < last_index, do: line <> "\n", else: line
      {{line, offset}, offset + byte_size(line)}
    end)
    |> elem(0)
  end

  defp overlap?(left, right) do
    left.start < right.start + right.length and right.start < left.start + left.length
  end

  defp marker_roots(source) do
    digest =
      :crypto.hash(:sha256, source)
      |> Base.encode16(case: :lower)
      |> binary_part(0, 12)

    %{
      default: collision_free_root(source, "__GLOSSIA_TOKEN_#{digest}_"),
      # Keep the marker in the same syntactic class that the prompt tells the model to preserve.
      url:
        collision_free_root(
          source,
          "https://glossia.invalid/protected-token/#{digest}/"
        )
    }
  end

  defp marker("urls", %{url: root}, index), do: "#{root}#{index}"
  defp marker(_kind, %{default: root}, index), do: "#{root}#{index}__"

  defp collision_free_root(source, root) do
    if String.contains?(source, root), do: collision_free_root(source, root <> "x"), else: root
  end
end
