defmodule Glossia.Quality.DOM do
  @moduledoc false

  @block_closing_tags ~r{</(?:address|article|aside|blockquote|br|button|dd|div|dl|dt|figcaption|figure|footer|form|h[1-6]|header|hr|li|main|nav|ol|p|section|table|td|th|tr|ul)>}iu

  def parse(html, page_url) when is_binary(html) and is_binary(page_url) do
    html = normalize_document(html)

    %{
      title: title(html),
      document_locale: document_locale(html),
      visible_text: visible_text(html),
      alternate_links: alternate_links(html, page_url),
      content_hash: content_hash(html)
    }
  end

  def text_blocks(text) when is_binary(text) do
    text
    |> String.split("\n")
    |> Enum.map(&normalize_space/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp normalize_document(output) do
    output =
      case :binary.match(output, "<!DOCTYPE") do
        {index, _length} -> binary_part(output, index, byte_size(output) - index)
        :nomatch -> normalize_from_html_tag(output)
      end

    trim_after_document(output)
  end

  defp normalize_from_html_tag(output) do
    case Regex.run(~r/<html\b/iu, output, return: :index) do
      [{index, _length}] -> binary_part(output, index, byte_size(output) - index)
      _ -> output
    end
  end

  defp trim_after_document(output) do
    case Regex.run(~r{</html\s*>}iu, output, return: :index) do
      [{index, length}] -> binary_part(output, 0, index + length)
      _ -> output
    end
  end

  defp title(html) do
    case Regex.run(~r/<title\b[^>]*>(.*?)<\/title>/isu, html, capture: :all_but_first) do
      [value] -> value |> strip_tags() |> decode_entities() |> normalize_space() |> blank_to_nil()
      _ -> nil
    end
  end

  defp document_locale(html) do
    case Regex.run(~r/<html\b[^>]*>/iu, html) do
      [tag] -> attribute(tag, "lang") |> normalize_locale() |> blank_to_nil()
      _ -> nil
    end
  end

  defp visible_text(html) do
    html
    |> String.replace(~r/<!--.*?-->/su, " ")
    |> String.replace(
      ~r/<(?:head|script|style|svg|noscript)\b[^>]*>.*?<\/(?:head|script|style|svg|noscript)>/isu,
      " "
    )
    |> String.replace(@block_closing_tags, "\n")
    |> strip_tags()
    |> decode_entities()
    |> String.split("\n")
    |> Enum.map(&normalize_space/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
    |> truncate(200_000)
  end

  defp alternate_links(html, page_url) do
    ~r/<(?:link|a)\b[^>]*>/iu
    |> Regex.scan(html)
    |> Enum.reduce(%{}, fn [tag], links ->
      locale = attribute(tag, "hreflang")
      href = attribute(tag, "href")

      if present?(locale) and present?(href) do
        case absolute_address(page_url, href) do
          nil -> links
          address -> Map.put_new(links, normalize_locale(locale), address)
        end
      else
        links
      end
    end)
  end

  defp absolute_address(page_url, href) do
    page_url
    |> URI.merge(href)
    |> URI.to_string()
  rescue
    ArgumentError -> nil
  end

  defp attribute(tag, name) do
    pattern = ~r/\b#{Regex.escape(name)}\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/iu

    case Regex.run(pattern, tag, capture: :all_but_first) do
      values when is_list(values) ->
        Enum.find(values, fn value -> is_binary(value) and value != "" end)

      _ ->
        nil
    end
  end

  defp strip_tags(value), do: String.replace(value, ~r/<[^>]+>/u, " ")

  defp decode_entities(value) do
    value
    |> String.replace("&nbsp;", " ")
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
  end

  defp normalize_space(value), do: value |> String.trim() |> String.replace(~r/\s+/u, " ")
  defp normalize_locale(nil), do: nil

  defp normalize_locale(locale) do
    locale
    |> String.trim()
    |> String.replace("_", "-")
    |> String.downcase()
    |> truncate(64)
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
  defp truncate(value, limit) when byte_size(value) <= limit, do: value

  defp truncate(value, limit) do
    value
    |> binary_part(0, limit)
    |> valid_prefix()
  end

  defp valid_prefix(value) do
    if String.valid?(value) do
      value
    else
      value |> binary_part(0, byte_size(value) - 1) |> valid_prefix()
    end
  end

  defp content_hash(value) do
    :sha256
    |> :crypto.hash(value)
    |> Base.encode16(case: :lower)
  end
end
