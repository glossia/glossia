defmodule Glossia.Docs.Page do
  @enforce_keys [:id, :title, :summary, :category, :order, :slug, :body]
  defstruct [:id, :title, :summary, :category, :order, :slug, :body, :markdown, toc: []]

  def build(filename, attrs, body) do
    parts = filename |> Path.rootname() |> Path.split()
    id = Enum.join(parts, "/")
    slug = List.last(parts)

    markdown =
      filename
      |> File.read!()
      |> String.split(~r/\n---\n/, parts: 2)
      |> List.last()
      |> String.trim_leading()

    {body_with_ids, toc} = inject_heading_ids(body)
    body_with_ids = transform_admonitions(body_with_ids)

    struct!(
      __MODULE__,
      Map.merge(attrs, %{id: id, slug: slug, body: body_with_ids, toc: toc, markdown: markdown})
    )
  end

  defp inject_heading_ids(html) do
    # Match h2 and h3 tags, extract text, inject id attributes
    {toc_entries, updated_html} =
      Regex.scan(~r/<(h[23])>(.*?)<\/\1>/s, html, return: :index)
      |> Enum.reduce({[], html}, fn [
                                      {full_start, full_len},
                                      {tag_start, tag_len},
                                      {text_start, text_len}
                                    ],
                                    {toc, current_html} ->
        tag = binary_part(html, tag_start, tag_len)
        text = binary_part(html, text_start, text_len)
        # Strip any inner HTML tags for the TOC label and ID
        plain_text = Regex.replace(~r/<[^>]+>/, text, "")
        anchor_id = slugify(plain_text)
        level = if tag == "h2", do: 2, else: 3

        full_match = binary_part(html, full_start, full_len)

        replacement =
          ~s(<#{tag} id="#{anchor_id}"><a href="##{anchor_id}" class="heading-anchor">#{text}</a></#{tag}>)

        updated = String.replace(current_html, full_match, replacement, global: false)

        entry = %{id: anchor_id, text: plain_text, level: level}
        {toc ++ [entry], updated}
      end)

    {updated_html, toc_entries}
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
