defmodule Glossia.Translations.Markdown do
  @moduledoc """
  Reassembles a translated Markdown fragment from the source document tree.

  Markdown is both prose and syntax. A language model may translate the visible
  text of a link correctly while normalizing or changing its destination. This
  module treats the source tree as authoritative for every non-text node and
  takes only text-node literals from the translated tree. The result preserves
  link destinations, code, images, headings, lists, and other document
  structure without asking the model to reproduce those values byte-for-byte.
  """

  @recovery_marker ~r/@@GLOSSIA-TEXT-\d+-(?:START|END)@@/

  @doc """
  Reconciles translated Markdown with `source`.

  Both fragments must have the same tree shape. Text nodes come from the
  translation; all other nodes and attributes stay with the source document.
  """
  def reconcile(source, translated) when is_binary(source) and is_binary(translated) do
    with {:ok, source_document} <- parse(source, "source"),
         {:ok, translated_document} <- parse(translated, "translated"),
         {:ok, document} <- merge(source_document, translated_document, "document") do
      {:ok, MDEx.to_markdown!(document)}
    end
  rescue
    error in ArgumentError ->
      {:error, "Markdown could not be reassembled: #{Exception.message(error)}"}
  end

  @doc "Whether a non-empty Markdown fragment must be reassembled from its source tree."
  def requires_reconciliation?(markdown) when is_binary(markdown) do
    with {:ok, document} <- MDEx.parse_document(markdown) do
      match?(%{nodes: [_ | _]}, document)
    else
      _ -> false
    end
  end

  @doc """
  Marks every translatable text node in a Markdown fragment.

  The markers allow a recovery translation to alter prose without having to
  reproduce Markdown syntax. `reconcile_marked_text_nodes/2` uses the markers
  to put the translated literals back into the source tree.
  """
  def mark_text_nodes(markdown) when is_binary(markdown) do
    with {:ok, document} <- parse(markdown, "source") do
      {document, _next_index} = mark_text_nodes(document, 1)
      {:ok, MDEx.to_markdown!(document)}
    end
  rescue
    error in ArgumentError ->
      {:error, "Markdown could not be prepared for recovery: #{Exception.message(error)}"}
  end

  @doc """
  Rebuilds source Markdown with text delimited by recovery markers.

  Unlike `reconcile/2`, the candidate need not retain Markdown syntax. Every
  source node and attribute remains authoritative, while only the text between
  matching marker pairs is used for the translated literals.
  """
  def reconcile_marked_text_nodes(source, translated)
      when is_binary(source) and is_binary(translated) do
    with {:ok, source_document} <- parse(source, "source"),
         source_literals <- text_node_literals(source_document),
         {:ok, literals} <- marked_literals(translated, source_literals),
         {document, []} <- replace_text_nodes(source_document, literals) do
      {:ok, MDEx.to_markdown!(document)}
    else
      {:error, _message} = error -> error
      _ -> {:error, "Markdown recovery markers did not match the source text nodes"}
    end
  rescue
    error in ArgumentError ->
      {:error, "Markdown could not be reassembled: #{Exception.message(error)}"}
  end

  defp parse(markdown, label) do
    case MDEx.parse_document(markdown) do
      {:ok, document} -> {:ok, document}
      {:error, reason} -> {:error, "#{label} Markdown could not be parsed: #{inspect(reason)}"}
    end
  end

  defp mark_text_nodes(%MDEx.Text{literal: literal} = node, index) do
    {%{node | literal: "#{marker_start(index)}#{literal}#{marker_end(index)}"}, index + 1}
  end

  defp mark_text_nodes(%{nodes: nodes} = node, index) when is_struct(node) do
    {nodes, index} = Enum.map_reduce(nodes, index, &mark_text_nodes/2)
    {%{node | nodes: nodes}, index}
  end

  defp mark_text_nodes(node, index), do: {node, index}

  defp text_node_literals(%MDEx.Text{literal: literal}), do: [literal]

  defp text_node_literals(%{nodes: nodes}) when is_list(nodes) do
    Enum.flat_map(nodes, &text_node_literals/1)
  end

  defp text_node_literals(_node), do: []

  defp marked_literals(_translated, []),
    do: {:error, "Markdown source had no text nodes for marker recovery"}

  defp marked_literals(translated, source_literals) do
    source_literals
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, {0, []}}, fn {source_literal, index}, {:ok, {offset, literals}} ->
      expected_start = marker_start(index)
      expected_end = marker_end(index)

      with {:ok, {start_marker, _start_at, start_after}} <- next_marker(translated, offset),
           ^expected_start <- start_marker,
           {:ok, {end_marker, end_at, end_after}} <- next_marker(translated, start_after),
           ^expected_end <- end_marker,
           raw_literal <- binary_part(translated, start_after, end_at - start_after),
           {:ok, literal} <- decode_marked_literal(raw_literal),
           true <- valid_marked_literal?(source_literal, literal) do
        {:cont, {:ok, {end_after, [literal | literals]}}}
      else
        {:error, _message} = error ->
          {:halt, error}

        false ->
          {:halt, {:error, "Markdown recovery marker #{index} had an empty translation"}}

        _ ->
          {:halt, {:error, "Markdown recovery markers were missing, duplicated, or reordered"}}
      end
    end)
    |> case do
      {:ok, {offset, literals}} ->
        case next_marker(translated, offset) do
          :error ->
            {:ok, Enum.reverse(literals)}

          {:ok, _marker} ->
            {:error, "Markdown recovery markers were missing, duplicated, or reordered"}
        end

      error ->
        error
    end
  end

  defp next_marker(text, offset) do
    remainder = binary_part(text, offset, byte_size(text) - offset)

    case Regex.run(@recovery_marker, remainder, return: :index) do
      [{relative_start, length}] ->
        start = offset + relative_start
        {:ok, {binary_part(text, start, length), start, start + length}}

      nil ->
        :error
    end
  end

  # `MDEx.to_markdown!/1` escapes Markdown-significant characters in text
  # nodes. Marker recovery receives that rendered source, so parse each model
  # literal before putting it back into a text node; assigning the raw rendered
  # bytes would escape those characters a second time on the final render.
  defp decode_marked_literal(literal) do
    trimmed = String.trim(literal)

    if trimmed == "" do
      {:ok, literal}
    else
      leading_size = byte_size(literal) - byte_size(String.trim_leading(literal))
      trailing_size = byte_size(literal) - byte_size(String.trim_trailing(literal))
      leading = binary_part(literal, 0, leading_size)
      trailing = binary_part(literal, byte_size(literal) - trailing_size, trailing_size)

      with {:ok, document} <- parse(trimmed, "translation") do
        {:ok, leading <> (document |> text_node_literals() |> Enum.join()) <> trailing}
      end
    end
  end

  defp valid_marked_literal?("", _literal), do: true

  defp valid_marked_literal?(source_literal, literal) do
    literal != "" and
      (String.trim(source_literal) == "" or String.trim(literal) != "")
  end

  defp replace_text_nodes(%MDEx.Text{} = node, [literal | rest]),
    do: {%{node | literal: literal}, rest}

  defp replace_text_nodes(%{nodes: nodes} = node, literals) when is_struct(node) do
    {nodes, literals} =
      Enum.map_reduce(nodes, literals, fn child, remaining ->
        replace_text_nodes(child, remaining)
      end)

    {%{node | nodes: nodes}, literals}
  end

  defp replace_text_nodes(node, literals), do: {node, literals}

  defp marker_start(index), do: "@@GLOSSIA-TEXT-#{index}-START@@"
  defp marker_end(index), do: "@@GLOSSIA-TEXT-#{index}-END@@"

  defp merge(%MDEx.Text{} = source, %MDEx.Text{} = translated, _path),
    do: {:ok, %{source | literal: translated.literal}}

  # Models sometimes add emphasis around an otherwise plain text node. The
  # source document owns that presentation, so retain it while taking the
  # translated words. Treating this as a structural failure makes a harmless
  # decoration change consume every retry, particularly for headings.
  defp merge(%MDEx.Text{} = source, translated, path) when is_struct(translated) do
    case inline_literal(translated) do
      {:ok, literal} -> {:ok, %{source | literal: literal}}
      :error -> structure_changed(source, translated, path)
    end
  end

  # A model can render a Markdown heading as a bold paragraph. Preserve the
  # source heading rather than failing the entire file, but only for simple
  # headings whose source text has one unambiguous destination.
  defp merge(
         %MDEx.Heading{nodes: [%MDEx.Text{} = source_text]} = source,
         %MDEx.Paragraph{} = translated,
         _path
       ) do
    case inline_nodes_literal(translated.nodes) do
      {:ok, literal} -> {:ok, %{source | nodes: [%{source_text | literal: literal}]}}
      :error -> {:error, "translated Markdown changed the document structure"}
    end
  end

  defp merge(source, translated, path) when is_struct(source) and is_struct(translated) do
    cond do
      source.__struct__ != translated.__struct__ ->
        structure_changed(source, translated, path)

      Map.has_key?(source, :nodes) and Map.has_key?(translated, :nodes) ->
        merge_children(source, translated, path)

      true ->
        {:ok, source}
    end
  end

  defp merge(_source, _translated, path),
    do: {:error, "translated Markdown changed the document structure at #{path}"}

  defp inline_literal(%MDEx.Text{literal: literal}), do: {:ok, literal}

  defp inline_literal(%MDEx.Emph{nodes: nodes}), do: inline_nodes_literal(nodes)
  defp inline_literal(%MDEx.Strong{nodes: nodes}), do: inline_nodes_literal(nodes)

  defp inline_literal(_node), do: :error

  defp inline_nodes_literal(nodes) do
    nodes
    |> Enum.reduce_while({:ok, []}, fn node, {:ok, literals} ->
      case inline_literal(node) do
        {:ok, literal} -> {:cont, {:ok, [literal | literals]}}
        :error -> {:halt, :error}
      end
    end)
    |> case do
      {:ok, literals} -> {:ok, literals |> Enum.reverse() |> Enum.join()}
      :error -> :error
    end
  end

  defp structure_changed(source, translated, path) do
    {:error,
     "translated Markdown changed the document structure at #{path}: expected #{node_name(source)}, got #{node_name(translated)}"}
  end

  defp merge_children(%{nodes: source_nodes}, %{nodes: translated_nodes}, path)
       when length(source_nodes) != length(translated_nodes) do
    {:error,
     "translated Markdown changed the document structure at #{path}: expected #{length(source_nodes)} children, got #{length(translated_nodes)}"}
  end

  defp merge_children(%{nodes: source_nodes} = source, %{nodes: translated_nodes}, path) do
    source_nodes
    |> Enum.zip(translated_nodes)
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, []}, fn {{source_node, translated_node}, index}, {:ok, nodes} ->
      case merge(source_node, translated_node, "#{path}.#{index}") do
        {:ok, node} -> {:cont, {:ok, [node | nodes]}}
        {:error, _message} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, nodes} -> {:ok, %{source | nodes: Enum.reverse(nodes)}}
      {:error, _message} = error -> error
    end
  end

  defp node_name(%module{}), do: module |> Module.split() |> List.last()
end
