defmodule Glossia.Features.Page do
  @enforce_keys [
    :id,
    :title,
    :summary,
    :slug,
    :body,
    :order,
    :icon,
    :hero_cta_text,
    :hero_cta_url,
    :highlights
  ]
  defstruct [
    :id,
    :title,
    :summary,
    :slug,
    :body,
    :order,
    :icon,
    :hero_cta_text,
    :hero_cta_url,
    :highlights
  ]

  def build(filename, attrs, body) do
    id =
      filename
      |> Path.rootname()
      |> Path.split()
      |> List.last()

    slug = Map.get(attrs, :slug, id)
    body = body |> inject_heading_ids() |> transform_admonitions()

    struct!(
      __MODULE__,
      Map.merge(attrs, %{id: id, slug: slug, body: body})
    )
  end

  defp inject_heading_ids(html) do
    Regex.scan(~r/<(h[23])>(.*?)<\/\1>/s, html, return: :index)
    |> Enum.reduce(html, fn [
                              {full_start, full_len},
                              {tag_start, tag_len},
                              {text_start, text_len}
                            ],
                            current_html ->
      tag = binary_part(html, tag_start, tag_len)
      text = binary_part(html, text_start, text_len)
      plain_text = Regex.replace(~r/<[^>]+>/, text, "")
      anchor_id = slugify(plain_text)

      full_match = binary_part(html, full_start, full_len)

      replacement =
        ~s(<#{tag} id="#{anchor_id}"><a href="##{anchor_id}" class="heading-anchor">#{text}</a></#{tag}>)

      String.replace(current_html, full_match, replacement, global: false)
    end)
  end

  @admonition_types ~w(NOTE TIP IMPORTANT WARNING CAUTION)

  defp transform_admonitions(html) do
    Regex.replace(
      ~r/<blockquote>\s*<p>\s*\[!(#{Enum.join(@admonition_types, "|")})\]\s*(.*?)<\/blockquote>/s,
      html,
      fn _full, type, content ->
        kind = String.downcase(type)
        label = String.capitalize(kind)

        ~s(<div class="admonition admonition-#{kind}"><p class="admonition-title">#{label}</p>#{content}</div>)
      end
    )
  end

  defp slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
end
