defmodule Glossia.Translations.InputDetails do
  @moduledoc """
  Raw-free diagnostic detail for translation dependency nodes.

  These details are recorded beside, not inside, the generation fingerprint.
  Adding diagnostic coverage must never invalidate an accepted translation.
  Repository section headings and context paths identify the affected input;
  private voice, glossary values, prompts and commands are fingerprinted only.
  """

  alias Glossia.Translations.Context
  alias Glossia.Translations.Fingerprint

  def attach(node, input) do
    node
    |> Map.put("details", details(node["kind"], node["label"], input))
    |> update_in(["children"], &Enum.map(&1, fn child -> attach(child, input) end))
  end

  defp details("source", _, input), do: %{"content_hash" => sections(input.source_content)}

  defp details("translation_config", _, input) do
    %{
      "validation_hash" => %{
        "check_cmd_hash" => Fingerprint.hash(Map.get(input, :check_cmd)),
        "check_cmds" =>
          Map.new(Map.get(input, :check_cmds) || %{}, fn {format, command} ->
            {format, %{"command_hash" => Fingerprint.hash(command)}}
          end),
        "argv_hash" => Fingerprint.hash(Map.get(input, :validation)),
        "relative_path" => Map.get(input, :validation_relative_path)
      }
    }
  end

  defp details("decision_config", _, input) do
    config = Map.get(input, :decision_model) || %{}

    %{
      "configuration_hash" => %{
        "handle" => Map.get(config, :handle),
        "model" => Map.get(config, :model),
        "minimum_score" => Map.get(config, :decision_min_score),
        "base_url_hash" => Fingerprint.hash(Map.get(config, :base_url))
      }
    }
  end

  defp details("context", "project", input),
    do: documents(Map.get(input, :context_documents, []))

  defp details("context", "locale", input),
    do: documents(Map.get(input, :locale_documents, []))

  defp details("context", "voice", input),
    do: %{"content_hash" => Context.input_details(input.server_context).voice}

  defp details("context", "terminology", input),
    do: %{"content_hash" => Context.input_details(input.server_context).glossary}

  defp details(_, _, _), do: %{}

  defp documents([]), do: %{}

  defp documents(documents) do
    %{
      "content_hash" =>
        Map.new(documents, fn document ->
          {document.relative_path,
           Map.put(sections(document.body), "content_hash", Fingerprint.hash(document.body))}
        end)
    }
  end

  defp sections(content) do
    # Bounded diagnostics, not a second copy of a potentially enormous document.
    chunks = Regex.split(~r/(?=^[#]{1,6} )/m, content, trim: true)

    {entries, _counts} =
      chunks
      |> Enum.take(200)
      |> Enum.map_reduce(%{}, fn chunk, counts ->
        heading =
          if String.starts_with?(chunk, "#"),
            do: chunk |> String.split("\n", parts: 2) |> hd() |> String.slice(0, 160),
            else: "Preamble"

        occurrence = Map.get(counts, heading, 0) + 1
        label = if occurrence == 1, do: heading, else: "#{heading} [#{occurrence}]"

        {{label, %{"content_hash" => Fingerprint.hash(chunk)}},
         Map.put(counts, heading, occurrence)}
      end)

    %{
      "sections" => Map.new(entries),
      "sections_omitted" => max(length(chunks) - 200, 0),
      "omitted_sections_hash" => Fingerprint.hash(Enum.drop(chunks, 200))
    }
  end
end
