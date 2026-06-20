defmodule Glossia.MarketingMarkdown do
  @moduledoc false

  @heading_regex ~r/<(h[23])>(.*?)<\/\1>/s

  def process(html, opts \\ []) do
    {html, toc} = add_heading_anchors(html, Keyword.get(opts, :toc, false))

    {transform_admonitions(html), toc}
  end

  def strip_html(html) do
    html
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp add_heading_anchors(html, build_toc?) do
    toc =
      if build_toc? do
        @heading_regex
        |> Regex.scan(html)
        |> Enum.map(fn [_match, tag, contents] ->
          text = strip_html(contents)

          %{
            id: slugify(text),
            text: text,
            level: if(tag == "h2", do: 2, else: 3)
          }
        end)
      else
        []
      end

    html =
      Regex.replace(@heading_regex, html, fn _match, tag, contents ->
        text = strip_html(contents)
        id = slugify(text)

        ~s(<#{tag} id="#{id}"><a href="##{id}" class="heading-anchor">#{contents}</a></#{tag}>)
      end)

    {html, toc}
  end

  defp transform_admonitions(html) do
    Regex.replace(
      ~r/<blockquote>\s*<p>\s*\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*(.*?)<\/blockquote>/s,
      html,
      fn _match, type, contents ->
        kind = String.downcase(type)
        label = String.capitalize(kind)

        ~s(<div class="admonition admonition-#{kind}"><p class="admonition-title">#{label}</p><p>#{contents}</div>)
      end
    )
  end

  defp slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^\p{L}\p{N}\s_-]+/u, "")
    |> String.replace(~r/\s+/u, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end
end
