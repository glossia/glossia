defmodule Glossia.Docs do
  defmodule Source do
    @moduledoc false

    @callback all_pages() :: [map()]
    @callback categories() :: map()
    @callback pages_by_category(String.t()) :: [map()]
    @callback subcategories_for(String.t()) :: [map()]
    @callback subcategory!(String.t(), String.t()) :: map()
    @callback pages_by_subcategory(String.t(), String.t()) :: [map()]
    @callback get_page!(String.t(), String.t()) :: map()
    @callback get_subcategory_page!(String.t(), String.t(), String.t()) :: map()
    @callback search_index() :: [map()]
  end

  def all_pages(), do: Glossia.Extensions.docs().all_pages()
  def categories(), do: Glossia.Extensions.docs().categories()
  def pages_by_category(category), do: Glossia.Extensions.docs().pages_by_category(category)
  def subcategories_for(category), do: Glossia.Extensions.docs().subcategories_for(category)
  def subcategory!(category, key), do: Glossia.Extensions.docs().subcategory!(category, key)

  def pages_by_subcategory(category, subcategory) do
    Glossia.Extensions.docs().pages_by_subcategory(category, subcategory)
  end

  def get_page!(category, slug), do: Glossia.Extensions.docs().get_page!(category, slug)

  def get_subcategory_page!(category, subcategory, slug) do
    Glossia.Extensions.docs().get_subcategory_page!(category, subcategory, slug)
  end

  def search_index(), do: Glossia.Extensions.docs().search_index()
end

defmodule Glossia.Docs.Empty do
  @moduledoc false

  @behaviour Glossia.Docs.Source

  @impl true
  def all_pages, do: []

  @impl true
  def categories, do: %{}

  @impl true
  def pages_by_category(_category), do: []

  @impl true
  def subcategories_for(_category), do: []

  @impl true
  def subcategory!(category, key) do
    raise Glossia.Docs.NotFoundError, "subcategory #{category}/#{key} not found"
  end

  @impl true
  def pages_by_subcategory(_category, _subcategory), do: []

  @impl true
  def get_page!(category, slug) do
    raise Glossia.Docs.NotFoundError, "doc page with category=#{category} slug=#{slug} not found"
  end

  @impl true
  def get_subcategory_page!(category, subcategory, slug) do
    raise Glossia.Docs.NotFoundError,
          "doc page with category=#{category} subcategory=#{subcategory} slug=#{slug} not found"
  end

  @impl true
  def search_index, do: []
end

defmodule Glossia.Docs.NotFoundError do
  defexception [:message, plug_status: 404]
end
