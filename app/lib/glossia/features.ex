defmodule Glossia.Features do
  defmodule Source do
    @moduledoc false

    @callback all_pages() :: [map()]
    @callback get_page_by_slug!(String.t()) :: map()
  end

  def all_pages, do: Glossia.Extensions.features().all_pages()
  def get_page_by_slug!(slug), do: Glossia.Extensions.features().get_page_by_slug!(slug)
end

defmodule Glossia.Features.Empty do
  @moduledoc false

  @behaviour Glossia.Features.Source

  @impl true
  def all_pages, do: []

  @impl true
  def get_page_by_slug!(slug) do
    raise Glossia.Features.NotFoundError, "feature page with slug=#{slug} not found"
  end
end

defmodule Glossia.Features.NotFoundError do
  defexception [:message, plug_status: 404]
end
