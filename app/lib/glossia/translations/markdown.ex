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

  defp parse(markdown, label) do
    case MDEx.parse_document(markdown) do
      {:ok, document} -> {:ok, document}
      {:error, reason} -> {:error, "#{label} Markdown could not be parsed: #{inspect(reason)}"}
    end
  end

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
