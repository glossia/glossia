defmodule Glossia.Translations.NativeCatalog do
  @moduledoc """
  Lossless value extraction for quoted Apple and Android string catalogs.

  Keys, comments, XML attributes, and delimiters stay in the source. Only decoded
  values go to the translator. Unsupported resource syntax fails before a model
  request, so resource keys are never translated as prose.
  """

  alias Glossia.Translations.JsonArray
  alias Glossia.Translations.PreservedTokens

  @trivia ~S"(?:[\s\x{FEFF}]+|//[^\n]*|/\*[\s\S]*?\*/)"
  @quoted ~S/"(?:[^"\\\r\n]|\\.)*"/
  @apple ~r/#{@trivia}+|#{@quoted}#{@trivia}*=#{@trivia}*(#{@quoted})#{@trivia}*;/u
  @android ~r/[\s\x{FEFF}]+|<\?xml[^?]*\?>|<!--[\s\S]*?-->|<resources\s*>|<\/resources>|<string\s+[^<>]*\btranslatable\s*=\s*["']false["'][^<>]*>[^<]*<\/string>|<string\s+[^<>]*>([^<]*)<\/string>/u
  @arguments ~r/%%|%(?:(\d+)\$)?([-+0 #,(]*(?:\d+)?(?:\.\d+)?)(hh|ll|[hljztLq])?([@diuoxXfFeEgGaAcCsSp])|%(?:\d+\$)?[-+0 #<,(]*(?:\d+|\*(?:\d+\$)?)?(?:\.(?:\d+|\*(?:\d+\$)?))?(?:hh|ll|[hljztLq])?(?:[tT][a-zA-Z]|[a-zA-Z@%])|%/u
  @escape ~r/\\(?:[uU][\da-fA-F]{4}|.)/u

  def plan(path, source) do
    extension = path |> Path.extname() |> String.downcase()

    pattern =
      case extension do
        ".strings" -> @apple
        ".xml" -> if Regex.match?(~r/<resources(?:\s|>)/, source), do: @android
        _ -> nil
      end

    if pattern do
      build_plan(pattern, extension, source) ||
        {:error, {:validation_failed, "native catalog source uses unsupported syntax"}}
    end
  end

  defp build_plan(pattern, extension, source) do
    if Regex.replace(pattern, source, "") == "" do
      values =
        Regex.scan(pattern, source, return: :index)
        |> Enum.flat_map(fn
          [_, {start, length}] when start >= 0 ->
            raw = binary_part(source, start, length)
            decoded = if extension == ".xml", do: decode_xml(raw), else: raw
            [{start, length, decode_string(String.trim(decoded), extension)}]

          _ ->
            []
        end)

      if Enum.all?(values, fn {_, _, value} -> is_binary(value) end),
        do: %{source: source, extension: extension, values: values}
    end
  rescue
    # Invalid Unicode character references are unsupported source syntax too.
    ArgumentError -> nil
  end

  def decode_values(text, sources, preserve_kinds) do
    with {:ok, values} <- JsonArray.decode(text),
         true <- length(values) == length(sources) and Enum.all?(values, &is_binary/1) do
      if Enum.zip(sources, values)
         |> Enum.all?(fn {source, value} ->
           (String.trim(source) == "" or String.trim(value) != "") and
             arguments(source) == arguments(value) and
             isolates(source) == isolates(value) and
             (not balanced_isolates?(source) or balanced_isolates?(value)) and
             PreservedTokens.unpreserved_values(source, value, preserve_kinds) == [] and
             PreservedTokens.unpreserved_values(value, source, preserve_kinds) == [] and
             not Regex.match?(~r/[\x00-\x08\x0b\x0c\x0e-\x1f]/, value)
         end) do
        {:ok, JSON.encode!(values)}
      else
        {:error,
         "native text-literal response changed a format argument, isolate, or empty value"}
      end
    else
      _ -> {:error, "native text-literal response must be a matching JSON array of strings"}
    end
  end

  def splice(plan, translations) do
    {parts, cursor} =
      Enum.zip(plan.values, translations)
      |> Enum.map_reduce(0, fn
        {{start, length, value}, value}, cursor ->
          # Equivalent decoded values keep their original escape spelling.
          {binary_part(plan.source, cursor, start + length - cursor), start + length}

        {{start, length, _}, value}, cursor ->
          encoded = JSON.encode!(value)

          encoded =
            if plan.extension == ".xml" do
              @escape
              |> Regex.replace(encoded, fn
                "\\r" -> "\\u000d"
                escape -> escape
              end)
              |> encode_xml()
            else
              encoded
            end

          {[binary_part(plan.source, cursor, start - cursor), encoded], start + length}
      end)

    IO.iodata_to_binary([
      parts,
      binary_part(plan.source, cursor, byte_size(plan.source) - cursor)
    ])
  end

  defp decode_string(raw, extension) do
    escapes = Regex.scan(@escape, raw) |> List.flatten()

    if Enum.all?(escapes, &supported_escape?(&1, extension)) do
      json =
        Regex.replace(@escape, raw, fn
          "\\U" <> code -> "\\u" <> code
          "\\" <> escape when escape in ["'", "@", "?"] -> escape
          escape -> escape
        end)

      case JSON.decode(json) do
        {:ok, value} when is_binary(value) -> value
        _ -> nil
      end
    end
  end

  defp supported_escape?("\\U" <> code, ".strings"), do: byte_size(code) == 4
  defp supported_escape?("\\u" <> code, ".xml"), do: byte_size(code) == 4

  defp supported_escape?("\\" <> char, ".strings"),
    do: char in ["n", "r", "t", "\"", "'", "\\", "/"]

  defp supported_escape?("\\" <> char, ".xml"),
    do: char in ["n", "t", "\"", "'", "\\", "@", "?"]

  defp decode_xml(raw) do
    Regex.replace(~r/&(amp|lt|gt|quot|apos|#\d+|#x[\da-fA-F]+);/, raw, fn _, entity ->
      case entity do
        "amp" -> "&"
        "lt" -> "<"
        "gt" -> ">"
        "quot" -> "\""
        "apos" -> "'"
        "#x" <> hex -> <<String.to_integer(hex, 16)::utf8>>
        "#" <> decimal -> <<String.to_integer(decimal)::utf8>>
      end
    end)
  end

  defp encode_xml(value) do
    value
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp arguments(value) do
    matches = Regex.scan(@arguments, value)

    # Complex directives stay byte-for-byte intact. Normalizing their implicit
    # argument indexes would also require accounting for dynamic width/precision
    # and Java's previous-argument flag, not just the value's conversion.
    if Enum.any?(matches, &match?([literal] when literal not in ["%", "%%"], &1)) do
      {:verbatim, Enum.map(matches, &hd/1)}
    else
      {tokens, _} =
        Enum.map_reduce(matches, 0, fn
          [literal], index ->
            {literal, index}

          [_, position, options, modifier, type], index ->
            {"#{if position == "", do: index + 1, else: position}:#{options}#{modifier}#{type}",
             if(position == "", do: index + 1, else: index)}
        end)

      {:normalized, Enum.sort(tokens)}
    end
  end

  defp isolates(value), do: Regex.scan(~r/[\x{2066}-\x{2069}]/u, value) |> Enum.frequencies()

  defp balanced_isolates?(value) do
    value
    |> then(&Regex.scan(~r/[\x{2066}-\x{2069}]/u, &1))
    |> Enum.reduce_while(0, fn
      ["\u2069"], 0 -> {:halt, :unbalanced}
      ["\u2069"], depth -> {:cont, depth - 1}
      _, depth -> {:cont, depth + 1}
    end)
    |> Kernel.==(0)
  end
end
