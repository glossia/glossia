defmodule Glossia.Site do
  @moduledoc false

  @callback all_blog_posts() :: [map()]
  @callback recent_blog_posts(pos_integer()) :: [map()]
  @callback blog_post_by_slug!(String.t()) :: map()

  @callback all_changelog_entries() :: [map()]

  @callback all_feature_pages() :: [map()]
  @callback feature_page_by_slug!(String.t()) :: map()

  @callback all_docs_pages() :: [map()]
  @callback docs_categories() :: map()
  @callback docs_pages_by_category(String.t()) :: [map()]
  @callback docs_subcategories_for(String.t()) :: [map()]
  @callback docs_subcategory!(String.t(), String.t()) :: map()
  @callback docs_pages_by_subcategory(String.t(), String.t()) :: [map()]
  @callback doc_page!(String.t(), String.t()) :: map()
  @callback doc_subcategory_page!(String.t(), String.t(), String.t()) :: map()
  @callback docs_search_index() :: [map()]

  defmodule Empty do
    @moduledoc false

    @behaviour Glossia.Site

    @impl true
    def all_blog_posts, do: []

    @impl true
    def recent_blog_posts(_count \\ 2), do: []

    @impl true
    def blog_post_by_slug!(slug) do
      raise Glossia.Site.NotFoundError, "blog post with slug=#{slug} not found"
    end

    @impl true
    def all_changelog_entries, do: []

    @impl true
    def all_feature_pages, do: []

    @impl true
    def feature_page_by_slug!(slug) do
      raise Glossia.Site.NotFoundError, "feature page with slug=#{slug} not found"
    end

    @impl true
    def all_docs_pages, do: []

    @impl true
    def docs_categories, do: %{}

    @impl true
    def docs_pages_by_category(_category), do: []

    @impl true
    def docs_subcategories_for(_category), do: []

    @impl true
    def docs_subcategory!(category, key) do
      raise Glossia.Site.NotFoundError, "subcategory #{category}/#{key} not found"
    end

    @impl true
    def docs_pages_by_subcategory(_category, _subcategory), do: []

    @impl true
    def doc_page!(category, slug) do
      raise Glossia.Site.NotFoundError,
            "doc page with category=#{category} slug=#{slug} not found"
    end

    @impl true
    def doc_subcategory_page!(category, subcategory, slug) do
      raise Glossia.Site.NotFoundError,
            "doc page with category=#{category} subcategory=#{subcategory} slug=#{slug} not found"
    end

    @impl true
    def docs_search_index, do: []
  end
end

defmodule Glossia.Site.NotFoundError do
  defexception [:message, plug_status: 404]
end
