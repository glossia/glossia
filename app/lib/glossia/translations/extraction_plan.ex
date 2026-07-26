defmodule Glossia.Translations.ExtractionPlan do
  @moduledoc """
  Builds a lossless plan for content that must not be translated.

  Producers identify protected source regions. This module validates those
  regions, slices their values from the original source, replaces them with
  context-shaped markers, and restores the exact bytes after translation.

  Future model-assisted producers can describe regions with exact excerpts and
  surrounding anchors through `from_locators/3`. They never provide replacement
  text or byte offsets; Glossia resolves and validates every source slice.
  """

  @enforce_keys [:source_digest, :text, :regions, :replacements]
  defstruct [:source_digest, :text, :regions, :replacements]

  @type range :: %{
          required(:start) => non_neg_integer(),
          required(:length) => pos_integer(),
          required(:kind) => String.t() | atom(),
          optional(:value) => String.t()
        }

  @type locator :: %{
          required(:excerpt) => String.t(),
          required(:occurrence) => pos_integer(),
          required(:kind) => String.t() | atom(),
          optional(:before) => String.t(),
          optional(:after) => String.t()
        }

  @type region :: %{
          start: non_neg_integer(),
          length: pos_integer(),
          kind: String.t(),
          value: String.t(),
          marker: String.t()
        }

  @type t :: %__MODULE__{
          source_digest: String.t(),
          text: String.t(),
          regions: [region()],
          replacements: [{String.t(), String.t()}]
        }

  @doc """
  Builds a plan from byte ranges produced by a deterministic source scanner.

  The optional `:scope` participates in marker generation so separately planned
  parts of the same document cannot produce identical markers.
  """
  @spec build(String.t(), [range()], keyword()) :: {:ok, t()} | {:error, String.t()}
  def build(source, ranges, opts \\ [])
      when is_binary(source) and is_list(ranges) and is_list(opts) do
    scope = to_string(Keyword.get(opts, :scope, "content"))

    with {:ok, ranges} <- normalize_ranges(source, ranges),
         :ok <- validate_non_overlapping(ranges) do
      plan = assemble(source, ranges, scope)

      case restore(plan.text, plan) do
        {:ok, ^source} -> {:ok, plan}
        {:ok, _other} -> {:error, "extraction plan failed its lossless round-trip check"}
        {:error, _message} = error -> error
      end
    end
  end

  @doc "Builds a plan and raises when a deterministic producer returned invalid ranges."
  @spec build!(String.t(), [range()], keyword()) :: t()
  def build!(source, ranges, opts \\ []) do
    case build(source, ranges, opts) do
      {:ok, plan} -> plan
      {:error, message} -> raise ArgumentError, message
    end
  end

  @doc """
  Resolves exact source locators and builds a lossless extraction plan.

  A locator selects an exact excerpt by occurrence after optional immediate
  `:before` and `:after` anchors are applied. Ambiguous, missing, overlapping,
  or invalid locators fail closed.
  """
  @spec from_locators(String.t(), [locator()], keyword()) ::
          {:ok, t()} | {:error, String.t()}
  def from_locators(source, locators, opts \\ [])
      when is_binary(source) and is_list(locators) and is_list(opts) do
    locators
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, []}, fn {locator, index}, {:ok, ranges} ->
      case resolve_locator(source, locator, index) do
        {:ok, range} -> {:cont, {:ok, [range | ranges]}}
        {:error, _message} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, ranges} -> build(source, Enum.reverse(ranges), opts)
      {:error, _message} = error -> error
    end
  end

  @doc "Restores every protected region, requiring each marker exactly once."
  @spec restore(String.t(), t()) :: {:ok, String.t()} | {:error, String.t()}
  def restore(output, %__MODULE__{regions: regions}) when is_binary(output) do
    case Enum.find(regions, fn region -> marker_count(output, region.marker) != 1 end) do
      nil ->
        restored =
          Enum.reduce(regions, output, fn region, text ->
            String.replace(text, region.marker, region.value)
          end)

        {:ok, restored}

      region ->
        count = marker_count(output, region.marker)

        {:error,
         "protected token marker occurred #{count} times; preserve it exactly once for #{inspect(region.value)}"}
    end
  end

  defp normalize_ranges(source, ranges) do
    ranges
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, []}, fn {range, index}, {:ok, normalized} ->
      case normalize_range(source, range, index) do
        {:ok, value} -> {:cont, {:ok, [value | normalized]}}
        {:error, _message} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.sort_by(normalized, & &1.start)}
      {:error, _message} = error -> error
    end
  end

  defp normalize_range(source, range, index) when is_map(range) do
    start = field(range, :start)
    length = field(range, :length)
    kind = field(range, :kind)

    cond do
      not (is_integer(start) and start >= 0) ->
        {:error, "extraction range #{index} has an invalid start"}

      not (is_integer(length) and length > 0) ->
        {:error, "extraction range #{index} has an invalid length"}

      start + length > byte_size(source) ->
        {:error, "extraction range #{index} falls outside the source"}

      is_nil(kind) or to_string(kind) == "" ->
        {:error, "extraction range #{index} has no kind"}

      true ->
        value = binary_part(source, start, length)

        case field(range, :value) do
          expected when is_binary(expected) and expected != value ->
            {:error, "extraction range #{index} does not match the original source"}

          _ ->
            {:ok,
             %{
               start: start,
               length: length,
               kind: to_string(kind),
               value: value
             }}
        end
    end
  end

  defp normalize_range(_source, _range, index),
    do: {:error, "extraction range #{index} must be a map"}

  defp validate_non_overlapping(ranges) do
    ranges
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.find(fn [left, right] -> left.start + left.length > right.start end)
    |> case do
      nil ->
        :ok

      [left, right] ->
        {:error,
         "extraction ranges overlap at byte #{right.start}: #{inspect(left.value)} and #{inspect(right.value)}"}
    end
  end

  defp assemble(source, [], _scope) do
    %__MODULE__{
      source_digest: digest(source),
      text: source,
      regions: [],
      replacements: []
    }
  end

  defp assemble(source, ranges, scope) do
    roots = marker_roots(source, scope)

    {parts, cursor, regions} =
      ranges
      |> Enum.with_index()
      |> Enum.reduce({[], 0, []}, fn {range, index}, {parts, cursor, regions} ->
        marker = marker(range.kind, range.value, roots, index)
        prefix = binary_part(source, cursor, range.start - cursor)
        region = Map.put(range, :marker, marker)

        {
          [marker, prefix | parts],
          range.start + range.length,
          [region | regions]
        }
      end)

    tail = binary_part(source, cursor, byte_size(source) - cursor)
    regions = Enum.reverse(regions)

    %__MODULE__{
      source_digest: digest(source),
      text: IO.iodata_to_binary(Enum.reverse([tail | parts])),
      regions: regions,
      replacements: Enum.map(regions, &{&1.marker, &1.value})
    }
  end

  defp resolve_locator(source, locator, index) when is_map(locator) do
    excerpt = field(locator, :excerpt)
    occurrence = field(locator, :occurrence)
    kind = field(locator, :kind)
    before = field(locator, :before)
    after_text = field(locator, :after)

    cond do
      not (is_binary(excerpt) and excerpt != "") ->
        {:error, "source locator #{index} has an empty excerpt"}

      not (is_integer(occurrence) and occurrence > 0) ->
        {:error, "source locator #{index} has an invalid occurrence"}

      is_nil(kind) or to_string(kind) == "" ->
        {:error, "source locator #{index} has no kind"}

      not (is_nil(before) or is_binary(before)) ->
        {:error, "source locator #{index} has an invalid before anchor"}

      not (is_nil(after_text) or is_binary(after_text)) ->
        {:error, "source locator #{index} has an invalid after anchor"}

      true ->
        matches =
          source
          |> :binary.matches(excerpt)
          |> Enum.filter(fn {start, length} ->
            before_matches?(source, start, before) and
              after_matches?(source, start + length, after_text)
          end)

        case Enum.at(matches, occurrence - 1) do
          nil ->
            {:error,
             "source locator #{index} occurrence #{occurrence} was not found for #{inspect(excerpt)}"}

          {start, length} ->
            {:ok, %{start: start, length: length, value: excerpt, kind: to_string(kind)}}
        end
    end
  end

  defp resolve_locator(_source, _locator, index),
    do: {:error, "source locator #{index} must be a map"}

  defp before_matches?(_source, _start, nil), do: true

  defp before_matches?(source, start, before) do
    length = byte_size(before)
    start >= length and binary_part(source, start - length, length) == before
  end

  defp after_matches?(_source, _end, nil), do: true

  defp after_matches?(source, end_offset, after_text) do
    length = byte_size(after_text)

    end_offset + length <= byte_size(source) and
      binary_part(source, end_offset, length) == after_text
  end

  defp marker("urls", _value, %{url: root}, index), do: "#{root}#{index}/value"

  defp marker("inline_code", _value, %{token: root}, index),
    do: "`#{root}#{index}`"

  defp marker("placeholders", value, %{token: root}, index) do
    if String.starts_with?(value, "{{") do
      "{{" <> root <> Integer.to_string(index) <> "}}"
    else
      "{#{root}#{index}}"
    end
  end

  defp marker("code_blocks", value, %{token: root}, index) do
    fence =
      case Regex.run(~r/\A[ \t]{0,3}(`{3,}|~{3,})/, value, capture: :all_but_first) do
        [opening] -> opening
        _ -> "```"
      end

    "#{fence}glossia-protected\n#{root}#{index}\n#{fence}"
  end

  defp marker(_kind, _value, %{default: root}, index), do: "#{root}#{index}__"

  defp marker_roots(source, scope) do
    marker_digest = digest(scope <> <<0>> <> source) |> binary_part(0, 12)

    %{
      default: collision_free_root(source, "__GLOSSIA_TOKEN_#{marker_digest}_"),
      token: collision_free_root(source, "glossia_protected_#{marker_digest}_"),
      url:
        collision_free_root(
          source,
          "https://glossia.invalid/protected-token/#{marker_digest}/"
        )
    }
  end

  defp collision_free_root(source, root) do
    if String.contains?(source, root), do: collision_free_root(source, root <> "x"), else: root
  end

  defp marker_count(output, marker), do: length(:binary.matches(output, marker))

  defp digest(value) do
    :crypto.hash(:sha256, value)
    |> Base.encode16(case: :lower)
  end

  defp field(map, key), do: Map.get(map, key, Map.get(map, Atom.to_string(key)))
end
