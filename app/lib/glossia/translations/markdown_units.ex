defmodule Glossia.Translations.MarkdownUnits do
  @moduledoc """
  Translates Markdown by splicing prose into the original source bytes.

  Re-rendering a translated document through a Markdown serializer rewrites
  bytes that were never meant to change: it escapes Phoenix components
  (`<.home_card>` becomes `\\<.home\\_card\\>`), GitHub alerts, and explicit
  heading anchors, and it normalizes list markers and line wrapping. This
  module never serializes. It parses the source only to find the prose, hands
  that prose to the model, and writes each translation back into the exact
  byte range it came from. Every byte outside those ranges stays identical.

  ## Units

  A unit is one block of prose: a paragraph, heading, or table cell, a prose
  attribute of a component or HTML block (`title`, `details`, `alt`, ...), or
  the text of an HTML `<summary>`. Translating whole blocks rather than single
  text nodes keeps a sentence together, so the model can reorder words around
  a link or emphasis the way the target language needs.

  Inline syntax inside a block becomes numbered tags in the unit's template:

    * `<gN>...</gN>` wraps formatted or linked text (emphasis, strong, links,
      image alt text). The text inside is translated; the delimiters, link
      destinations, and titles come back from the source.
    * `<gN/>` stands for content that must not change at all: inline code,
      inline HTML or components, explicit heading anchors, hard line breaks.

  Soft line breaks become spaces, because a translation cannot keep the
  source's wrapping anyway.

  ## Guarantees

  `render/2` rejects a translation that drops, duplicates, renames, or
  misnests a tag. `check/3` re-parses the document with a candidate spliced in
  and compares its structure to the source's, which catches a translation that
  introduces Markdown syntax of its own. `render/3` with `escape: true` escapes
  Markdown punctuation in that unit's prose only, as a last resort.
  """

  @parse_options [
    extension: [
      alerts: true,
      phoenix_heex: true,
      strikethrough: true,
      table: true,
      tasklist: true,
      footnotes: true
    ]
  ]

  # Blocks whose children are inline content.
  @inline_blocks [MDEx.Paragraph, MDEx.Heading, MDEx.TableCell]

  # Inline nodes whose children are themselves translatable inline content.
  @inline_containers [
    MDEx.Emph,
    MDEx.Strong,
    MDEx.Link,
    MDEx.Image,
    MDEx.Strikethrough,
    MDEx.Superscript,
    MDEx.Subscript,
    MDEx.Underline,
    MDEx.SpoileredText
  ]

  @prose_attributes ~w(title details summary label description alt placeholder aria-label caption)
  @attribute_regex ~r/(?<![\w-])(#{Enum.join(@prose_attributes, "|")})="([^"]*)"/
  @summary_regex ~r/<summary>([^<]+)<\/summary>/

  @tag_regex ~r/<(\/?)g(\d+)(\/?)>/

  @doc """
  Plans the units of a Markdown `source`.

  Returns `{:ok, plan}` with the source, its ordered units, and the structural
  signature translations are checked against.
  """
  def plan(source) when is_binary(source) do
    with {:ok, document} <- parse(source) do
      units =
        document
        |> collect(source, line_starts(source))
        |> Enum.sort_by(& &1.start)
        |> drop_overlapping()
        |> Enum.filter(&translatable?(&1.template))
        |> Enum.with_index(1)
        |> Enum.map(fn {unit, index} -> Map.put(unit, :id, "u#{index}") end)

      {:ok, %{source: source, units: units, signature: signature(document)}}
    end
  end

  @doc """
  Turns a translated template for `unit` into the bytes to splice in.

  Options: `escape: true` escapes Markdown punctuation in the translated prose,
  and separates emphasis delimiters when translated punctuation would stop them
  parsing as emphasis. Restored source syntax stays untouched.
  """
  def render(unit, translated, opts \\ [])

  # Prose the model left as it was, such as a product name, keeps its exact
  # source bytes, including line wrapping and escapes.
  def render(%{template: template, raw: raw}, template, _opts), do: {:ok, raw}

  def render(unit, translated, opts) when is_binary(translated) do
    with {:ok, tokens} <- tokenize(translated),
         :ok <- validate_tags(unit, tokens) do
      escape? = Keyword.get(opts, :escape, false)

      parts =
        tokens
        |> Enum.map(fn
          {:text, text} -> encode_text(unit.kind, normalize_text(text), escape?)
          {:open, n} -> unit.tags[n].open
          {:close, n} -> unit.tags[n].close
          {:atomic, n} -> unit.tags[n].bytes
        end)

      parts = if escape?, do: separate_emphasis(tokens, parts), else: parts
      rendered = IO.iodata_to_binary(parts)

      {:ok, trim_like(rendered, unit.template)}
    end
  end

  @doc "Splices rendered units (a map of unit id to bytes) into the source."
  def splice(%{source: source, units: units}, rendered) when is_map(rendered) do
    {parts, cursor} =
      Enum.reduce(units, {[], 0}, fn unit, {parts, cursor} ->
        case Map.fetch(rendered, unit.id) do
          {:ok, bytes} ->
            prefix = binary_part(source, cursor, unit.start - cursor)
            {[bytes, prefix | parts], unit.stop}

          :error ->
            {parts, cursor}
        end
      end)

    suffix = binary_part(source, cursor, byte_size(source) - cursor)
    IO.iodata_to_binary(Enum.reverse([suffix | parts]))
  end

  @doc """
  Whether splicing `rendered` keeps the document's Markdown structure.

  Returns `:ok` or `{:error, message}`.
  """
  def check(plan, rendered) when is_map(rendered) do
    case plan |> splice(rendered) |> parse() do
      {:ok, document} ->
        if signature(document) == plan.signature,
          do: :ok,
          else: {:error, "translated Markdown changed the document structure"}

      {:error, _reason} = error ->
        error
    end
  end

  @doc "Ids of units whose rendered bytes alone change the document structure."
  def structural_offenders(plan, rendered) when is_map(rendered) do
    rendered
    |> Enum.reject(fn {id, bytes} -> check(plan, %{id => bytes}) == :ok end)
    |> Enum.map(&elem(&1, 0))
  end

  @doc """
  The source surrounding `units`, for the model to read as context.

  Short documents are returned whole. Longer ones are clipped to the blocks
  around the units, on line boundaries.
  """
  def context(%{source: source}, units, opts \\ []) do
    max_bytes = Keyword.get(opts, :max_bytes, 16_000)
    margin = Keyword.get(opts, :margin_bytes, 3_000)

    if byte_size(source) <= max_bytes or units == [] do
      source
    else
      first = units |> Enum.map(& &1.start) |> Enum.min()
      last = units |> Enum.map(& &1.stop) |> Enum.max()
      start = source |> line_start_before(max(first - margin, 0))
      stop = source |> line_end_after(min(last + margin, byte_size(source)))
      binary_part(source, start, stop - start)
    end
  end

  # ── Parsing ───────────────────────────────────────────────────────────────

  defp parse(source) do
    case MDEx.parse_document(source, @parse_options) do
      {:ok, document} -> {:ok, document}
      {:error, reason} -> {:error, "Markdown could not be parsed: #{inspect(reason)}"}
    end
  end

  defp line_starts(source) do
    offsets = source |> :binary.matches("\n") |> Enum.map(fn {offset, 1} -> offset + 1 end)
    List.to_tuple([0 | offsets])
  end

  # MDEx source positions are 1-based lines and 1-based byte columns, with an
  # inclusive end. Returns a half-open byte range, or nil for a node without a
  # usable position.
  defp range(%{sourcepos: %{start: {sl, sc}, end: {el, ec}}}, starts)
       when sl > 0 and sc > 0 and el > 0 and ec >= 0 and sl <= tuple_size(starts) and
              el <= tuple_size(starts) do
    {elem(starts, sl - 1) + sc - 1, elem(starts, el - 1) + ec}
  end

  defp range(_node, _starts), do: nil

  # ── Collecting units ──────────────────────────────────────────────────────

  defp collect(%module{nodes: children} = node, source, starts) when module in @inline_blocks do
    case inline_unit(node, children, source, starts) do
      nil -> []
      unit -> [unit]
    end
  end

  defp collect(%MDEx.HeexBlock{node: "expression"}, _source, _starts), do: []

  defp collect(%MDEx.HeexBlock{literal: literal} = node, source, starts) do
    case range(node, starts) do
      {start, _stop} ->
        {component, trailing} = split_component(literal)

        literal_units(component, start, source) ++
          trailing_units(trailing, start + byte_size(component), source)

      nil ->
        []
    end
  end

  defp collect(%MDEx.HtmlBlock{literal: literal} = node, source, starts) do
    case range(node, starts) do
      {start, _stop} -> literal_units(literal, start, source)
      nil -> []
    end
  end

  defp collect(%MDEx.CodeBlock{}, _source, _starts), do: []

  defp collect(%{nodes: children}, source, starts) when is_list(children),
    do: Enum.flat_map(children, &collect(&1, source, starts))

  defp collect(_node, _source, _starts), do: []

  defp inline_unit(_node, [], _source, _starts), do: nil

  defp inline_unit(node, children, source, starts) do
    content = Enum.reject(children, &break?/1)

    with [_ | _] <- content,
         {start, _} <- range(hd(content), starts),
         {_, stop} <- range(List.last(content), starts),
         true <- start < stop,
         {:ok, {parts, tags}} <- template(children, source, starts, start, %{}) do
      %{
        kind: :markdown,
        block: node.__struct__,
        start: start,
        stop: stop,
        raw: binary_part(source, start, stop - start),
        template: IO.iodata_to_binary(parts),
        tags: tags
      }
    else
      _ -> nil
    end
  end

  # Builds a unit's template from inline `nodes`, starting at byte `cursor`.
  # Returns the template parts and the tag table, or :error when a position
  # cannot be trusted, in which case the block is left as it is.
  defp template(nodes, source, starts, cursor, tags) do
    nodes
    |> Enum.reduce_while({:ok, {[], tags, cursor, nil}}, fn node, {:ok, acc} ->
      case template_node(node, source, starts, acc) do
        {:ok, acc} -> {:cont, {:ok, acc}}
        :error -> {:halt, :error}
      end
    end)
    |> case do
      {:ok, {parts, tags, _cursor, _pending}} -> {:ok, {Enum.reverse(parts), tags}}
      :error -> :error
    end
  end

  defp template_node(%MDEx.SoftBreak{}, _source, _starts, {parts, tags, cursor, _}),
    do: {:ok, {parts, tags, cursor, :soft}}

  defp template_node(%MDEx.LineBreak{}, _source, _starts, {parts, tags, cursor, _}),
    do: {:ok, {parts, tags, cursor, :hard}}

  defp template_node(node, source, starts, {parts, tags, cursor, pending}) do
    with {start, stop} when start >= cursor <- range(node, starts) do
      gap = binary_part(source, cursor, start - cursor)
      {parts, tags} = gap_part(gap, pending, parts, tags)
      node_part(node, source, starts, {start, stop}, parts, tags)
    else
      _ -> :error
    end
  end

  # A soft break and the indentation or quote prefix after it collapse to a
  # space. A hard break keeps its exact bytes, as does any other gap the
  # parser left between two inline nodes.
  defp gap_part("", nil, parts, tags), do: {parts, tags}
  defp gap_part(_gap, :soft, parts, tags), do: {[" " | parts], tags}
  defp gap_part(gap, _pending, parts, tags), do: atomic(gap, parts, tags)

  defp node_part(%MDEx.Text{literal: literal}, _source, _starts, {_start, stop}, parts, tags) do
    # The literal has escapes and entities decoded. That is the prose the model
    # should read; a translation that needs an escape again is caught by
    # `check/2` and escaped by `render/3`.
    {:ok, {[literal | parts], tags, stop, nil}}
  end

  defp node_part(%module{nodes: [_ | _] = children}, source, starts, {start, stop}, parts, tags)
       when module in @inline_containers do
    content = Enum.reject(children, &break?/1)

    with [_ | _] <- content,
         {first, _} when first >= start <- range(hd(content), starts),
         {_, last} when last <= stop <- range(List.last(content), starts),
         n = map_size(tags) + 1,
         tags = Map.put(tags, n, %{type: :pair}),
         {:ok, {inner, tags}} <- template(children, source, starts, first, tags) do
      tag = %{
        type: :pair,
        open: binary_part(source, start, first - start),
        close: binary_part(source, last, stop - last)
      }

      parts = ["</g#{n}>", inner, "<g#{n}>" | parts]
      {:ok, {parts, Map.put(tags, n, tag), stop, nil}}
    else
      _ -> leaf(source, {start, stop}, parts, tags)
    end
  end

  defp node_part(_node, source, _starts, range, parts, tags), do: leaf(source, range, parts, tags)

  defp leaf(source, {start, stop}, parts, tags) do
    {parts, tags} = atomic(binary_part(source, start, stop - start), parts, tags)
    {:ok, {parts, tags, stop, nil}}
  end

  defp atomic(bytes, parts, tags) do
    n = map_size(tags) + 1
    {["<g#{n}/>" | parts], Map.put(tags, n, %{type: :atomic, bytes: bytes})}
  end

  defp break?(%MDEx.SoftBreak{}), do: true
  defp break?(%MDEx.LineBreak{}), do: true
  defp break?(_node), do: false

  # Prose attributes of a component or HTML block, and an HTML `<summary>`.
  # A block nested in a list or quote carries prefixes the literal does not,
  # so every candidate is checked against the source bytes at its offset and
  # skipped when they differ.
  defp literal_units(literal, block_start, source) do
    attributes =
      @attribute_regex
      |> Regex.scan(literal, return: :index)
      |> Enum.map(fn [_whole, _name, value] -> {:attribute, value} end)

    summaries =
      @summary_regex
      |> Regex.scan(literal, return: :index)
      |> Enum.map(fn [_whole, value] -> {:html_text, value} end)

    (attributes ++ summaries)
    |> Enum.flat_map(fn {kind, {offset, size}} ->
      value = binary_part(literal, offset, size)
      start = block_start + offset

      if start + size <= byte_size(source) and binary_part(source, start, size) == value do
        [%{kind: kind, start: start, stop: start + size, raw: value, template: value, tags: %{}}]
      else
        []
      end
    end)
  end

  # A multi-line, self-closing component (`<.card\n  title="..."\n/>`) does
  # not end its block for the parser, which then takes every following line
  # as part of the component. The component really ends at its own `/>` or
  # closing tag, so whatever comes after is planned as ordinary Markdown.
  defp trailing_units("", _offset, _source), do: []

  defp trailing_units(trailing, offset, source) do
    with true <- offset + byte_size(trailing) <= byte_size(source),
         true <- binary_part(source, offset, byte_size(trailing)) == trailing,
         {:ok, document} <- parse(trailing) do
      document
      |> collect(trailing, line_starts(trailing))
      |> Enum.map(&%{&1 | start: &1.start + offset, stop: &1.stop + offset})
    else
      _ -> []
    end
  end

  # Splits a HEEx block literal into the component itself and anything the
  # parser appended after it. Quoted attribute values and `{...}` expressions
  # are skipped while looking for the end of the opening tag.
  defp split_component("<." <> rest = literal) do
    name = rest |> String.split(~r/[\s\/>]/, parts: 2) |> hd()

    case opening_tag_end(literal, byte_size(name) + 2, nil, 0) do
      {:self_closing, stop} ->
        split_at_line_end(literal, stop)

      {:open, stop} ->
        closing = "</." <> name <> ">"

        case :binary.match(literal, closing, scope: {stop, byte_size(literal) - stop}) do
          {position, length} -> split_at_line_end(literal, position + length)
          :nomatch -> {literal, ""}
        end

      :error ->
        {literal, ""}
    end
  end

  defp split_component(literal), do: {literal, ""}

  defp opening_tag_end(literal, index, _quote, _depth) when index >= byte_size(literal),
    do: :error

  defp opening_tag_end(literal, index, quote, depth) do
    char = :binary.at(literal, index)

    cond do
      quote != nil and char == quote -> opening_tag_end(literal, index + 1, nil, depth)
      quote != nil -> opening_tag_end(literal, index + 1, quote, depth)
      char in [?", ?'] and depth == 0 -> opening_tag_end(literal, index + 1, char, depth)
      char == ?{ -> opening_tag_end(literal, index + 1, nil, depth + 1)
      char == ?} -> opening_tag_end(literal, index + 1, nil, max(depth - 1, 0))
      depth > 0 -> opening_tag_end(literal, index + 1, nil, depth)
      char == ?> and :binary.at(literal, index - 1) == ?/ -> {:self_closing, index + 1}
      char == ?> -> {:open, index + 1}
      true -> opening_tag_end(literal, index + 1, nil, depth)
    end
  end

  defp split_at_line_end(literal, stop) do
    stop =
      case :binary.match(literal, "\n", scope: {stop, byte_size(literal) - stop}) do
        {position, 1} -> position + 1
        :nomatch -> byte_size(literal)
      end

    {binary_part(literal, 0, stop), binary_part(literal, stop, byte_size(literal) - stop)}
  end

  defp drop_overlapping(units) do
    units
    |> Enum.reduce({[], -1}, fn unit, {kept, last_stop} ->
      if unit.start >= last_stop, do: {[unit | kept], unit.stop}, else: {kept, last_stop}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  defp translatable?(template),
    do: @tag_regex |> Regex.replace(template, "") |> String.match?(~r/\p{L}/u)

  # ── Rendering a translation ───────────────────────────────────────────────

  defp tokenize(text) do
    {tokens, cursor} =
      @tag_regex
      |> Regex.scan(text, return: :index)
      |> Enum.reduce({[], 0}, fn [{start, length}, {cs, cl}, {ns, nl}, {as, al}], {acc, cursor} ->
        closing? = cl > 0 and binary_part(text, cs, cl) == "/"
        atomic? = al > 0 and binary_part(text, as, al) == "/"
        n = text |> binary_part(ns, nl) |> String.to_integer()

        token =
          cond do
            atomic? -> {:atomic, n}
            closing? -> {:close, n}
            true -> {:open, n}
          end

        acc =
          if start > cursor,
            do: [{:text, binary_part(text, cursor, start - cursor)} | acc],
            else: acc

        {[token | acc], start + length}
      end)

    tokens =
      if cursor < byte_size(text),
        do: [{:text, binary_part(text, cursor, byte_size(text) - cursor)} | tokens],
        else: tokens

    {:ok, Enum.reverse(tokens)}
  end

  defp validate_tags(unit, tokens) do
    tag_tokens = Enum.reject(tokens, &match?({:text, _}, &1))
    expected = expected_tokens(unit.tags)

    cond do
      Enum.any?(tag_tokens, fn {_type, n} -> not Map.has_key?(unit.tags, n) end) ->
        {:error, "unknown tag; use only the tags present in the source text"}

      Enum.sort(tag_tokens) != Enum.sort(expected) ->
        {:error,
         "every tag must appear exactly once: #{Enum.map_join(expected, " ", &tag_text/1)}"}

      not nested?(tag_tokens) ->
        {:error, "paired tags must open before they close and must not overlap"}

      true ->
        :ok
    end
  end

  defp expected_tokens(tags) do
    Enum.flat_map(tags, fn
      {n, %{type: :pair}} -> [{:open, n}, {:close, n}]
      {n, %{type: :atomic}} -> [{:atomic, n}]
    end)
  end

  defp nested?(tokens) do
    tokens
    |> Enum.reduce_while([], fn
      {:open, n}, stack -> {:cont, [n | stack]}
      {:close, n}, [n | stack] -> {:cont, stack}
      {:close, _n}, _stack -> {:halt, :error}
      {:atomic, _n}, stack -> {:cont, stack}
    end)
    |> Kernel.==([])
  end

  defp tag_text({:open, n}), do: "<g#{n}>"
  defp tag_text({:close, n}), do: "</g#{n}>"
  defp tag_text({:atomic, n}), do: "<g#{n}/>"

  # A unit is one block, so a newline in the translation would start another.
  defp normalize_text(text), do: String.replace(text, ~r/\s*\n\s*/, " ")

  defp encode_text(:attribute, text, _escape?),
    do: text |> String.replace("&", "&amp;") |> String.replace("\"", "&quot;")

  defp encode_text(:html_text, text, _escape?),
    do: text |> String.replace("&", "&amp;") |> String.replace("<", "&lt;")

  defp encode_text(:markdown, text, false), do: text

  defp encode_text(:markdown, text, true) do
    escaped = Regex.replace(~r/[\\`*_\[\]<>#|~!]/, text, "\\\\\\0")

    # Text at the start of a block can also read as a list item.
    escaped
    |> then(&Regex.replace(~r/\A(\s*)([-+])(?=\s)/, &1, "\\1\\\\\\2"))
    |> then(&Regex.replace(~r/\A(\s*\d+)([.)])(?=\s)/, &1, "\\1\\\\\\2"))
  end

  # CommonMark emphasis is punctuation-sensitive: **申請。**続く is literal
  # text, not strong emphasis. Underscores also cannot form intraword emphasis,
  # as in は_非公開_です. Keep the source delimiters and separate only those
  # boundaries. The engine re-parses and checks the repair before accepting it.
  defp separate_emphasis(tokens, parts) do
    Enum.zip([tokens, parts, ["" | parts], Enum.drop(parts, 1) ++ [""]])
    |> Enum.map(fn
      {{:open, _}, delimiter, before, following} when delimiter in ["*", "**", "_", "__", "~~"] ->
        if String.match?(before, ~r/[^\s\p{Z}\p{P}\p{S}]\z/u) and
             (delimiter in ["_", "__"] or String.match?(following, ~r/\A[\p{P}\p{S}]/u)),
           do: " " <> delimiter,
           else: delimiter

      {{:close, _}, delimiter, before, following}
      when delimiter in ["*", "**", "_", "__", "~~"] ->
        if (delimiter in ["_", "__"] or String.match?(before, ~r/[\p{P}\p{S}]\z/u)) and
             String.match?(following, ~r/\A[^\s\p{Z}\p{P}\p{S}]/u),
           do: delimiter <> " ",
           else: delimiter

      {_token, bytes, _before, _following} ->
        bytes
    end)
  end

  defp trim_like(rendered, template) do
    rendered =
      if String.match?(template, ~r/\A\s/), do: rendered, else: String.trim_leading(rendered)

    if String.match?(template, ~r/\s\z/), do: rendered, else: String.trim_trailing(rendered)
  end

  # ── Structure ─────────────────────────────────────────────────────────────

  # Everything about a document except its prose: its blocks in order, the
  # inline syntax inside each block, and the values a translation must never
  # change. Text and soft breaks are left out, and block literals have their
  # prose masked, since those are exactly what a translation replaces.
  #
  # Within a block the inline syntax is compared as a set, because a
  # translation may legitimately move a link or a code span to follow the
  # target language's word order. Inline HTML and component tags keep their
  # order: swapping an opening and a closing tag would break the page.
  defp signature(%{nodes: nodes}), do: Enum.flat_map(nodes, &node_signature/1)

  defp node_signature(%module{nodes: children} = node) when module in @inline_blocks,
    do: [{module, node_values(node), inline_signature(children)}]

  defp node_signature(%MDEx.Text{}), do: []
  defp node_signature(%MDEx.SoftBreak{}), do: []

  defp node_signature(%module{} = node) do
    [
      {module, node_values(node)}
      | node |> Map.get(:nodes, []) |> Enum.flat_map(&node_signature/1)
    ]
  end

  defp inline_signature(children) do
    {children |> inline_nodes() |> Enum.sort(), children |> tag_literals() |> Enum.to_list()}
  end

  defp inline_nodes(children) do
    Enum.flat_map(children, fn
      %MDEx.Text{} ->
        []

      %MDEx.SoftBreak{} ->
        []

      %module{nodes: [_ | _] = nested} = node ->
        [{module, node_values(node), inline_signature(nested)}]

      %module{} = node ->
        [{module, node_values(node)}]
    end)
  end

  defp tag_literals(children) do
    Enum.flat_map(children, fn
      %module{literal: literal} when module in [MDEx.HtmlInline, MDEx.HeexInline] -> [literal]
      %{nodes: [_ | _] = nested} -> tag_literals(nested)
      _node -> []
    end)
  end

  defp node_values(%MDEx.Link{url: url, title: title}), do: {url, title}
  defp node_values(%MDEx.Image{url: url, title: title}), do: {url, title}
  defp node_values(%MDEx.Heading{level: level}), do: level
  defp node_values(%MDEx.Code{literal: literal}), do: literal
  defp node_values(%MDEx.CodeBlock{literal: literal, info: info}), do: {literal, info}
  defp node_values(%MDEx.HtmlInline{literal: literal}), do: literal
  defp node_values(%MDEx.HeexInline{literal: literal}), do: literal

  defp node_values(%MDEx.HeexBlock{node: "expression", literal: literal}), do: literal

  defp node_values(%MDEx.HeexBlock{literal: literal}) do
    {component, trailing} = split_component(literal)

    trailing_signature =
      case parse(trailing) do
        {:ok, document} -> signature(document)
        {:error, _reason} -> trailing
      end

    {mask_prose(component), trailing_signature}
  end

  defp node_values(%MDEx.HtmlBlock{literal: literal}), do: mask_prose(literal)

  defp node_values(%MDEx.List{} = list), do: {list.list_type, list.delimiter, list.bullet_char}
  defp node_values(%MDEx.Alert{alert_type: type}), do: type
  defp node_values(_node), do: nil

  defp mask_prose(literal) do
    literal
    |> then(&Regex.replace(@attribute_regex, &1, "\\1=\"\""))
    |> then(&Regex.replace(@summary_regex, &1, "<summary></summary>"))
  end

  # ── Context helpers ───────────────────────────────────────────────────────

  defp line_start_before(source, offset) do
    case source |> binary_part(0, offset) |> :binary.matches("\n") |> List.last() do
      {position, 1} -> position + 1
      nil -> 0
    end
  end

  defp line_end_after(source, offset) do
    case :binary.match(source, "\n", scope: {offset, byte_size(source) - offset}) do
      {position, 1} -> position + 1
      :nomatch -> byte_size(source)
    end
  end
end
