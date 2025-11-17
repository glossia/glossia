defmodule Glossia.Formats.XliffHandler do
  @moduledoc """
  Handles XLIFF (XML Localization Interchange File Format) files.
  """

  @behaviour Glossia.Formats.Handler

  import SweetXml

  @impl true
  def translate(content, source_locale, target_locale) do
    with {:ok, doc} <- parse_xml(content),
         {:ok, translated} <- translate_targets(content, doc, source_locale, target_locale) do
      {:ok, translated}
    end
  end

  @impl true
  def validate(content) do
    try do
      SweetXml.parse(content, dtd: :none)
      :ok
    rescue
      _ -> {:error, "Invalid XLIFF: not valid XML"}
    end
  end

  defp parse_xml(content) do
    try do
      doc = SweetXml.parse(content, dtd: :none)
      {:ok, doc}
    rescue
      e -> {:error, "Failed to parse XLIFF: #{Exception.message(e)}"}
    end
  end

  defp translate_targets(original_content, doc, source, target) do
    # Extract all <target> elements
    targets = doc |> xpath(~x"//target/text()"l)

    # Translate each target
    Enum.reduce_while(targets, {:ok, original_content}, fn target_text, {:ok, content_acc} ->
      text = to_string(target_text)

      if String.trim(text) == "" do
        {:cont, {:ok, content_acc}}
      else
        case Glossia.AI.Translator.translate(text, source, target) do
          {:ok, translated} ->
            # Replace in the original XML string to preserve formatting
            new_content = String.replace(content_acc, ">#{text}</target>", ">#{translated}</target>", global: false)
            {:cont, {:ok, new_content}}

          {:error, _} = error ->
            {:halt, error}
        end
      end
    end)
  end
end
