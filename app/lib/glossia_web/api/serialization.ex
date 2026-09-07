defmodule GlossiaWeb.Api.Serialization do
  @moduledoc false

  @spec meta(Flop.Meta.t()) :: map()
  def meta(%Flop.Meta{} = meta) do
    %{
      total_count: meta.total_count,
      total_pages: meta.total_pages,
      current_page: meta.current_page,
      page_size: meta.page_size,
      has_next_page?: meta.has_next_page?,
      has_previous_page?: meta.has_previous_page?
    }
  end
end
