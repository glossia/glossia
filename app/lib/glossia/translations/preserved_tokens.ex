defmodule Glossia.Translations.PreservedTokens do
  @moduledoc """
  Masks content that must survive translation and restores it afterwards.

  The masker deliberately recognizes a small, format-neutral set of atomic
  values rather than attempting to parse every Markdown extension. Fenced code,
  inline code, and placeholders are replaced with stable markers before a model
  sees the content.

  A plain web address stays visible: models reproduce a real address more
  reliably than a synthetic marker sitting in a Markdown link destination, and
  the validation step still requires its exact source value in the final output.
  An address that carries another protected value, such as a `{locale}` path
  segment, is masked whole instead, so the model never sees the half-real
  address it would otherwise be tempted to repair.
  """

  alias Glossia.Translations.ExtractionPlan

  @default_kinds ~w(code_blocks inline_code urls placeholders)
  @version 6
  @inline_code_regex ~r/`[^`\n]+`/

  # A bare address in prose has no closing delimiter, so the scan itself decides
  # where the address ends. Two rules keep that decision stable across locales.
  # Restricting the run to the ASCII characters an address can carry stops a
  # Japanese or Chinese sentence that continues straight after it — those
  # scripts put no space there — from being swallowed into the match. Trimming
  # sentence punctuation keeps "https://example.com." and "https://example.com。"
  # comparable, so a translation that ends its sentence differently from the
  # source is not mistaken for a dropped address.
  @url_regex ~r/https?:\/\/[A-Za-z0-9\-._~:\/?#\[\]@!$&*+,;=%({}]+/
  @url_trailing_punctuation ~r/[.,;:!?*_]+\z/
  @placeholder_regex ~r/\{\{[^{}\n]+\}\}|\{[^\s{}]+\}/

  @regex_kinds [
    {"inline_code", @inline_code_regex},
    {"urls", @url_regex},
    {"placeholders", @placeholder_regex}
  ]

  @type protection :: ExtractionPlan.t()

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

  @doc "Replaces model-sensitive source values with collision-resistant markers."
  @spec protect(String.t(), [String.t()], keyword()) :: protection()
  def protect(source, kinds, opts \\ [])
      when is_binary(source) and is_list(kinds) and is_list(opts) do
    nested = nested_ranges(source, kinds)
    mask_urls = Keyword.get(opts, :mask_urls, false)

    ExtractionPlan.build!(
      source,
      source |> ranges(kinds) |> Enum.reject(&visible_url?(&1, nested, mask_urls)),
      opts
    )
  end

  @doc "Markers the output reproduced the wrong number of times for `excerpt`."
  def unpreserved_markers(%ExtractionPlan{} = protection, excerpt, output),
    do: ExtractionPlan.unpreserved_markers(protection, excerpt, output)

  @doc """
  Values of `kinds` that `excerpt` carries but `output` does not reproduce.

  Counts matter: a value the excerpt uses twice has to come back twice. Unlike
  `unpreserved_markers/3` this compares the values themselves, so it also covers
  content left visible to the model, such as a plain web address.
  """
  def unpreserved_values(excerpt, output, kinds)
      when is_binary(excerpt) and is_binary(output) and is_list(kinds) do
    reproduced = output |> values(kinds) |> Enum.frequencies()

    excerpt
    |> values(kinds)
    |> Enum.frequencies()
    |> Enum.flat_map(fn {value, count} ->
      List.duplicate(value, max(count - Map.get(reproduced, value, 0), 0))
    end)
    |> Enum.sort()
  end

  @doc "Restores protected values, failing when a model changed or duplicated a marker."
  @spec restore(String.t(), protection()) :: {:ok, String.t()} | {:error, String.t()}
  def restore(output, %ExtractionPlan{} = protection) when is_binary(output),
    do: ExtractionPlan.restore(output, protection)

  defp ranges(source, kinds) do
    code_ranges =
      if "code_blocks" in kinds do
        fenced_code_ranges(source)
      else
        []
      end

    @regex_kinds
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

  # A web address only has to be masked when it carries another protected value.
  # `ranges/2` accepts addresses before placeholders, so an address that
  # overlaps nothing suppressed nothing: dropping it cannot leave a nested value
  # exposed, and the model gets to see the real address.
  defp visible_url?(%{kind: "urls"}, _nested_ranges, true), do: false

  defp visible_url?(%{kind: "urls"} = range, nested_ranges, false),
    do: not Enum.any?(nested_ranges, &overlap?(range, &1))

  defp visible_url?(_range, _nested_ranges, _mask_urls), do: false

  defp nested_ranges(source, kinds) do
    @regex_kinds
    |> Enum.filter(fn {kind, _regex} -> kind != "urls" and kind in kinds end)
    |> Enum.flat_map(fn {kind, regex} -> regex_ranges(source, regex, kind) end)
  end

  defp regex_ranges(source, regex, kind) do
    regex
    |> Regex.scan(source, return: :index, capture: :first)
    |> Enum.flat_map(fn [{start, length}] ->
      trim_range(%{
        start: start,
        length: length,
        value: binary_part(source, start, length),
        kind: kind
      })
    end)
  end

  # Sentence punctuation that follows a bare address is prose, not part of the
  # address, and the translation is free to change it.
  defp trim_range(%{kind: "urls"} = range) do
    case Regex.replace(@url_trailing_punctuation, range.value, "") do
      "" -> []
      trimmed -> [%{range | value: trimmed, length: byte_size(trimmed)}]
    end
  end

  defp trim_range(range), do: [range]

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
end
