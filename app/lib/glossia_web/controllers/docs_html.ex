defmodule GlossiaWeb.DocsHTML do
  use GlossiaWeb, :html

  import Noora.Card, only: [card: 1, card_section: 1]

  embed_templates "docs_html/*"

  @category_order ~w(tutorials how-to reference explanation)

  def sorted_categories(categories) do
    categories
    |> Enum.sort_by(fn {key, _meta} ->
      Enum.find_index(@category_order, &(&1 == key)) || 99
    end)
  end
end
