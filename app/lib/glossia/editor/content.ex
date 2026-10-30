defmodule Glossia.Editor.Content do
  @moduledoc """
  String-only editing of repository content.

  `fields/2` returns stable, opaque path IDs, display labels, and decoded values.
  `update/3` accepts a partial map of those IDs to strings. Unknown IDs and
  non-string values are errors; submitting unchanged values preserves every byte.

  JSON edits splice string tokens into the source, preserving all other bytes;
  duplicate object keys are rejected. YAML edits splice quoted scalars into the
  source, retaining surrounding comments and formatting, and verify the entire
  resulting document against the intended data. Anchors, aliases, explicit tags,
  directives, duplicate/non-string keys, multiple documents, and scalar spellings
  whose ranges cannot be established safely are rejected. Changed block strings
  become quoted strings with escaped newlines. Markdown exposes its body and
  YAML frontmatter strings, never raw metadata. TOML and Elixir frontmatter are
  intentionally unsupported rather than exposed as editable body text.
  """

  @doc "Returns editable string leaves, not structural or typed scalar values."
  def fields(format, content) when is_binary(content) do
    with {:ok, plan} <- plan(format, content) do
      {:ok, Enum.map(plan.fields, &Map.take(&1, [:id, :label, :value]))}
    end
  end

  @doc "Applies only recognized string fields, preserving the original on a no-op."
  def update(format, content, values) when is_binary(content) and is_map(values) do
    with {:ok, plan} <- plan(format, content),
         :ok <- validate_values(plan.fields, values) do
      changes =
        Enum.filter(plan.fields, fn field ->
          Map.has_key?(values, field.id) and values[field.id] != field.value
        end)

      if changes == [], do: {:ok, content}, else: render(plan, content, changes, values)
    end
  end

  def update(_format, _content, _values), do: {:error, "field values must be a map of strings"}

  defp plan(format, source) when format in [:text, "text"] do
    {:ok, %{kind: :text, fields: [%{id: "text", label: "Text", value: source}]}}
  end

  defp plan(format, source) when format in [:json, "json"] do
    with {:ok, _data} <- Jason.decode(source),
         {:ok, fields} <- json_fields(source) do
      {:ok, %{kind: :json, fields: fields}}
    else
      {:error, %Jason.DecodeError{} = reason} ->
        {:error, "invalid JSON: #{Exception.message(reason)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp plan(format, source) when format in [:yaml, "yaml"] do
    with {:ok, data, nodes} <- yaml_read(source),
         {:ok, fields} <- yaml_fields(source, nodes) do
      {:ok, %{kind: :yaml, data: data, fields: fields}}
    end
  end

  defp plan(format, source) when format in [:markdown, "markdown"] do
    markdown_plan(source)
  end

  defp plan(_format, _source), do: {:error, "unsupported content format"}

  # Jason validates syntax first. This walk only locates byte spans and checks
  # decoded keys for duplicates; numbers are never decoded and re-encoded.
  defp json_fields(source) do
    {_rest, _offset, fields} = json_value(source, 0, [])
    {:ok, fields}
  catch
    :duplicate_json_key -> {:error, "unsupported JSON: duplicate object keys are not editable"}
  end

  defp json_value(<<char, rest::binary>>, offset, path) when char in [32, 9, 10, 13],
    do: json_value(rest, offset + 1, path)

  defp json_value(<<?{, rest::binary>>, offset, path),
    do: json_members(rest, offset + 1, path, MapSet.new(), [])

  defp json_value(<<?[, rest::binary>>, offset, path),
    do: json_entries(rest, offset + 1, path, 0, [])

  defp json_value(<<?", _::binary>> = source, offset, path) do
    {rest, stop, value} = json_string(source, offset)
    {rest, stop, [Map.merge(field(path, value), %{start: offset, stop: stop})]}
  end

  defp json_value(source, offset, _path) do
    {rest, stop} = json_scalar(source, offset)
    {rest, stop, []}
  end

  defp json_members(source, offset, path, seen, children) do
    {source, offset} = json_whitespace(source, offset)

    case source do
      <<?}, rest::binary>> ->
        fields = children |> Enum.sort_by(&elem(&1, 0)) |> Enum.flat_map(&elem(&1, 1))
        {rest, offset + 1, fields}

      _ ->
        {rest, offset, key} = json_string(source, offset)
        if MapSet.member?(seen, key), do: throw(:duplicate_json_key)
        {<<?:, rest::binary>>, offset} = json_whitespace(rest, offset)
        {rest, offset, fields} = json_value(rest, offset + 1, path ++ [key])
        {rest, offset} = json_whitespace(rest, offset)
        children = [{key, fields} | children]
        seen = MapSet.put(seen, key)

        case rest do
          <<?,, rest::binary>> -> json_members(rest, offset + 1, path, seen, children)
          _ -> json_members(rest, offset, path, seen, children)
        end
    end
  end

  defp json_entries(source, offset, path, index, children) do
    {source, offset} = json_whitespace(source, offset)

    case source do
      <<?], rest::binary>> ->
        {rest, offset + 1, children |> Enum.reverse() |> List.flatten()}

      _ ->
        {rest, offset, fields} = json_value(source, offset, path ++ [index])
        {rest, offset} = json_whitespace(rest, offset)

        case rest do
          <<?,, rest::binary>> ->
            json_entries(rest, offset + 1, path, index + 1, [fields | children])

          _ ->
            json_entries(rest, offset, path, index + 1, [fields | children])
        end
    end
  end

  defp json_string(source, offset) do
    length = quoted_stop(source, 1, ?")
    <<token::binary-size(^length), rest::binary>> = source
    {rest, offset + length, Jason.decode!(token)}
  end

  defp json_scalar(<<char, rest::binary>>, offset)
       when char not in [32, 9, 10, 13, ?,, ?], ?}],
       do: json_scalar(rest, offset + 1)

  defp json_scalar(rest, offset), do: {rest, offset}

  defp json_whitespace(<<char, rest::binary>>, offset) when char in [32, 9, 10, 13],
    do: json_whitespace(rest, offset + 1)

  defp json_whitespace(rest, offset), do: {rest, offset}

  defp field(path, value) do
    %{
      id: "field:" <> Base.url_encode64(Jason.encode!(path), padding: false),
      label: Enum.reduce(path, "$", &label_segment/2),
      value: value,
      path: path
    }
  end

  defp label_segment(index, label) when is_integer(index), do: "#{label}[#{index}]"

  defp label_segment(key, label) do
    if Regex.match?(~r/\A[A-Za-z_][A-Za-z_0-9]*\z/, key),
      do: label <> "." <> key,
      else: label <> "[" <> Jason.encode!(key) <> "]"
  end

  defp validate_values(fields, values) do
    ids = MapSet.new(fields, & &1.id)

    cond do
      Enum.any?(values, fn {id, _} -> not MapSet.member?(ids, id) end) ->
        {:error, "unrecognized field ID"}

      Enum.any?(values, fn {_, value} -> not is_binary(value) or not String.valid?(value) end) ->
        {:error, "field values must be valid UTF-8 strings"}

      true ->
        :ok
    end
  end

  defp render(%{kind: :text}, _source, _changes, values), do: {:ok, values["text"]}

  defp render(%{kind: :json}, source, changes, values) do
    rendered =
      changes
      |> Enum.sort_by(& &1.start, :desc)
      |> Enum.reduce(source, fn field, content ->
        binary_part(content, 0, field.start) <>
          Jason.encode!(values[field.id]) <>
          binary_part(content, field.stop, byte_size(content) - field.stop)
      end)

    {:ok, rendered}
  end

  defp render(%{kind: :yaml, data: data}, source, changes, values) do
    expected = changed_data(data, changes, values)

    rendered =
      changes
      |> Enum.sort_by(& &1.start, :desc)
      |> Enum.reduce(source, fn field, content ->
        replacement = Jason.encode!(values[field.id]) <> field.suffix

        binary_part(content, 0, field.start) <>
          replacement <>
          binary_part(content, field.stop, byte_size(content) - field.stop)
      end)

    case yaml_read(rendered) do
      {:ok, ^expected, _} -> {:ok, rendered}
      _ -> {:error, "YAML edit cannot safely preserve document structure and metadata"}
    end
  end

  defp render(%{kind: :markdown} = plan, _source, changes, values) do
    metadata_changes = Enum.reject(changes, &(&1.id == "body"))

    with {:ok, metadata} <- render_metadata(plan, metadata_changes, values) do
      body = Map.get(values, "body", plan.body)
      {:ok, plan.open <> metadata <> plan.close <> body}
    end
  end

  defp render_metadata(%{metadata: nil}, _changes, _values), do: {:ok, ""}
  defp render_metadata(plan, [], _values), do: {:ok, plan.raw_metadata}

  defp render_metadata(plan, changes, values),
    do: render(plan.metadata, plan.raw_metadata, changes, values)

  defp changed_data(data, changes, values) do
    Enum.reduce(changes, data, fn field, acc -> replace_at(acc, field.path, values[field.id]) end)
  end

  defp replace_at(_data, [], value), do: value

  defp replace_at(data, [index | rest], value) when is_list(data),
    do: List.update_at(data, index, &replace_at(&1, rest, value))

  defp replace_at(data, [key | rest], value),
    do: Map.update!(data, key, &replace_at(&1, rest, value))

  # The translation frontmatter splitter normalizes CRLF and final newlines,
  # and its configuration parser drops arbitrary metadata. Keep byte fences here.
  defp markdown_plan(source) do
    cond do
      Regex.match?(~r/\A(?:\+\+\+[ \t]*(?:\r?\n|\z)|%\{)/, source) ->
        {:error, "unsupported Markdown frontmatter: only YAML is editable"}

      Regex.match?(~r/\A---[ \t]*(?:\r?\n|\z)/, source) ->
        fenced_markdown(source)

      true ->
        {:ok, markdown_body(source)}
    end
  end

  defp markdown_body(body) do
    %{
      kind: :markdown,
      metadata: nil,
      open: "",
      close: "",
      body: body,
      fields: [%{id: "body", label: "Body", value: body}]
    }
  end

  defp fenced_markdown(source) do
    [opening] = Regex.run(~r/\A---[^\n]*(?:\n|\z)/, source)
    rest = binary_part(source, byte_size(opening), byte_size(source) - byte_size(opening))

    case Regex.run(~r/^---[ \t]*\r?(?:\n|\z)/m, rest, return: :index) do
      [{start, length}] ->
        raw = binary_part(rest, 0, start)
        closing = binary_part(rest, start, length)
        body = binary_part(rest, start + length, byte_size(rest) - start - length)

        with {:ok, metadata} <- plan(:yaml, raw) do
          fields =
            Enum.map(metadata.fields, &Map.update!(&1, :id, fn id -> "frontmatter:" <> id end))

          metadata = %{metadata | fields: fields}

          {:ok,
           Map.merge(markdown_body(body), %{
             open: opening,
             close: closing,
             raw_metadata: raw,
             metadata: metadata,
             fields: fields ++ markdown_body(body).fields
           })}
        end

      nil ->
        {:error, "Markdown frontmatter has no closing --- fence"}
    end
  end

  # yamerl is yaml_elixir's parser. Detailed nodes retain scalar line/column
  # positions and duplicate keys, which the high-level mapper discards.
  defp yaml_read(source) do
    :yamerl_parser.string(source, token_fun: &safe_yaml_token/1)

    case :yamerl_constr.string(source,
           detailed_constr: true,
           str_node_as_binary: true,
           keep_duplicate_keys: true
         ) do
      [] ->
        {:ok, nil, []}

      [{:yamerl_doc, root}] ->
        {data, nodes} = yaml_node(root, [])
        {:ok, data, nodes}

      _ ->
        {:error, "unsupported YAML: multiple documents"}
    end
  catch
    {:unsupported_yaml, message} -> {:error, "unsupported YAML: " <> message}
    :throw, _ -> {:error, "invalid YAML"}
    :error, _ -> {:error, "invalid YAML"}
  end

  defp safe_yaml_token(token) do
    kind = elem(token, 0)

    if kind in [
         :yamerl_anchor,
         :yamerl_alias,
         :yamerl_yaml_directive,
         :yamerl_tag_directive,
         :yamerl_reserved_directive
       ] do
      throw({:unsupported_yaml, "anchors, aliases, and directives are not editable"})
    end

    if kind in [:yamerl_scalar, :yamerl_collection_start] do
      {:yamerl_tag, line, column, uri} = elem(token, 3)

      unless match?({:non_specific, _}, uri) and line == elem(token, 1) and
               column == elem(token, 2) do
        throw({:unsupported_yaml, "explicit tags are not editable"})
      end
    end

    :ok
  end

  defp yaml_node({:yamerl_map, _, _, _, pairs}, path) do
    Enum.reduce(pairs, {%{}, []}, fn
      {{:yamerl_str, _, _, _, key}, value}, {data, nodes} ->
        if key == "<<" or Map.has_key?(data, key),
          do: throw({:unsupported_yaml, "merge keys and duplicate keys are not editable"})

        {child, child_nodes} = yaml_node(value, path ++ [key])
        {Map.put(data, key, child), nodes ++ child_nodes}

      _, _ ->
        throw({:unsupported_yaml, "only string mapping keys are editable"})
    end)
  end

  defp yaml_node({:yamerl_seq, _, _, _, entries, _}, path) do
    {values, nodes} =
      entries
      |> Enum.with_index()
      |> Enum.map_reduce([], fn {entry, i}, nodes ->
        {value, child_nodes} = yaml_node(entry, path ++ [i])
        {value, nodes ++ child_nodes}
      end)

    {values, nodes}
  end

  defp yaml_node({:yamerl_str, _, _, position, value}, path),
    do: {value, [{field(path, value), position}]}

  defp yaml_node({:yamerl_null, _, _, _}, _path), do: {nil, []}

  defp yaml_node({kind, _, _, _, value}, _path)
       when kind in [:yamerl_int, :yamerl_float, :yamerl_bool],
       do: {value, []}

  defp yaml_node(_node, _path), do: throw({:unsupported_yaml, "unsupported scalar type"})

  defp yaml_fields(source, nodes) do
    Enum.reduce_while(nodes, {:ok, []}, fn {field, position}, {:ok, fields} ->
      start = byte_offset(source, position[:line], position[:column])

      case scalar_range(source, start, field.value) do
        {:ok, stop, suffix} ->
          {:cont,
           {:ok, fields ++ [Map.merge(field, %{start: start, stop: stop, suffix: suffix})]}}

        :error ->
          {:halt, {:error, "unsupported YAML: cannot safely locate string at #{field.label}"}}
      end
    end)
  end

  defp byte_offset(source, line, column) do
    lines = String.split(source, "\n")
    preceding = lines |> Enum.take(line - 1) |> Enum.reduce(0, &(byte_size(&1) + 1 + &2))
    # yamerl columns count Unicode codepoints, not UTF-8 bytes or graphemes.
    prefix = lines |> Enum.at(line - 1) |> String.codepoints() |> Enum.take(column - 1)
    preceding + IO.iodata_length(prefix)
  end

  defp scalar_range(source, start, value) do
    rest = binary_part(source, start, byte_size(source) - start)

    case rest do
      <<quote, _::binary>> when quote in [?", ?'] ->
        case quoted_stop(rest, 1, quote) do
          nil -> :error
          length -> {:ok, start + length, ""}
        end

      <<indicator, _::binary>> when indicator in [?|, ?>] ->
        block_range(source, start, rest)

      _ ->
        plain_range(rest, start, value)
    end
  end

  defp quoted_stop(text, i, _quote) when i >= byte_size(text), do: nil

  defp quoted_stop(text, i, quote) do
    case {binary_part(text, i, byte_size(text) - i), quote} do
      {<<"\\", _, _::binary>>, ?"} -> quoted_stop(text, i + 2, quote)
      {<<"''", _::binary>>, ?'} -> quoted_stop(text, i + 2, quote)
      {<<^quote, _::binary>>, _} -> i + 1
      _ -> quoted_stop(text, i + 1, quote)
    end
  end

  defp plain_range(rest, start, value) do
    [line | _] = String.split(rest, ~r/\r?\n/, parts: 2)
    # Parsing a scalar with its comment still yields the same value. Exclude
    # that comment before looking for a span, otherwise it would be replaced.
    [line | _] = Regex.split(~r/[ \t]+#/, line, parts: 2)

    candidates =
      [
        byte_size(line)
        | Enum.map(Regex.scan(~r/[,\]}]/, line, return: :index), fn [{i, _}] -> i end)
      ]
      |> Enum.sort(:desc)

    Enum.find_value(candidates, :error, fn length ->
      raw = line |> binary_part(0, length) |> String.trim_trailing()

      case YamlElixir.read_from_string(raw) do
        {:ok, ^value} -> {:ok, start + byte_size(raw), ""}
        _ -> nil
      end
    end)
  end

  defp block_range(source, start, rest) do
    [header | lines] = String.split(rest, "\n")
    prefix = source |> binary_part(0, start) |> String.split("\n") |> List.last()
    base_indent = if String.trim(prefix) == "", do: -1, else: indentation(prefix)

    base_indent =
      case Regex.run(~r/\A( *(?:- +)*).+:[ \t]*\z/, prefix) do
        [_, leading] -> byte_size(leading)
        nil -> base_indent
      end

    first = Enum.find(lines, &(String.trim(&1) != ""))

    indent =
      case Regex.run(~r/\A[|>][+-]?([1-9])/, header) do
        [_, digit] -> max(base_indent, 0) + String.to_integer(digit)
        nil -> max(if(first, do: indentation(first), else: 0), base_indent + 1)
      end

    content =
      Enum.take_while(lines, fn line ->
        not Regex.match?(~r/\A(?:---|\.\.\.)(?:[ \t\r]|\z)/, line) and
          (String.trim(line) == "" or indentation(line) >= indent)
      end)

    # Preserve the line separator before the next key, including CRLF.
    length =
      min(
        byte_size(rest),
        byte_size(header) + 1 + Enum.reduce(content, 0, &(byte_size(&1) + 1 + &2))
      )

    comment =
      case Regex.run(~r/[ \t]+#[^\r]*/, header) do
        [comment] -> comment
        nil -> ""
      end

    newline = if String.ends_with?(header, "\r"), do: "\r\n", else: "\n"

    suffix =
      comment <>
        if(String.ends_with?(binary_part(rest, 0, length), "\n"), do: newline, else: "")

    {:ok, start + length, suffix}
  end

  defp indentation(line), do: byte_size(line) - byte_size(String.trim_leading(line, " "))
end
