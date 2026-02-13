defmodule Glossia.Docs.Page do
  @enforce_keys [:id, :title, :summary, :category, :order, :slug, :body]
  defstruct [:id, :title, :summary, :category, :order, :slug, :body, toc: []]

  def build(filename, attrs, body) do
    parts = filename |> Path.rootname() |> Path.split()
    id = Enum.join(parts, "/")
    slug = List.last(parts)

    {body_with_ids, toc} = inject_heading_ids(body)

    struct!(
      __MODULE__,
      Map.merge(attrs, %{id: id, slug: slug, body: body_with_ids, toc: toc})
    )
  end

  defp inject_heading_ids(html) do
    # Match h2 and h3 tags, extract text, inject id attributes
    {toc_entries, updated_html} =
      Regex.scan(~r/<(h[23])>(.*?)<\/\1>/s, html, return: :index)
      |> Enum.reduce({[], html}, fn [{full_start, full_len}, {tag_start, tag_len}, {text_start, text_len}], {toc, current_html} ->
        tag = binary_part(html, tag_start, tag_len)
        text = binary_part(html, text_start, text_len)
        # Strip any inner HTML tags for the TOC label and ID
        plain_text = Regex.replace(~r/<[^>]+>/, text, "")
        anchor_id = slugify(plain_text)
        level = if tag == "h2", do: 2, else: 3

        full_match = binary_part(html, full_start, full_len)
        replacement = ~s(<#{tag} id="#{anchor_id}">#{text}</#{tag}>)
        updated = String.replace(current_html, full_match, replacement, global: false)

        entry = %{id: anchor_id, text: plain_text, level: level}
        {toc ++ [entry], updated}
      end)

    {updated_html, toc_entries}
  end

  defp slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
end
