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

  defdelegate all_pages(), to: Glossia.Extensions.docs()
  defdelegate categories(), to: Glossia.Extensions.docs()
  defdelegate pages_by_category(category), to: Glossia.Extensions.docs()
  defdelegate subcategories_for(category), to: Glossia.Extensions.docs()
  defdelegate subcategory!(category, key), to: Glossia.Extensions.docs()
  defdelegate pages_by_subcategory(category, subcategory), to: Glossia.Extensions.docs()
  defdelegate get_page!(category, slug), to: Glossia.Extensions.docs()
  defdelegate get_subcategory_page!(category, subcategory, slug), to: Glossia.Extensions.docs()
  defdelegate search_index(), to: Glossia.Extensions.docs()
end

defmodule Glossia.Docs.NotFoundError do
  defexception [:message, plug_status: 404]
end
