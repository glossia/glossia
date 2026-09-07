defmodule GlossiaWeb.MarketingRoutes do
  @moduledoc """
  The public marketing routes, defined once and mounted once per locale.

  English is served unprefixed (`/blog`) so every URL that is already indexed
  keeps working, and each translated locale gets its own literal prefix
  (`/es/blog`, `/zh-hans/docs/...`). The prefixes are literal rather than a
  `/:locale` segment on purpose: a dynamic segment would shadow every
  `/:handle/:project` page whose project is named `blog`, `docs`, `features`,
  and so on.
  """

  defmacro __using__(_opts) do
    quote do
      import GlossiaWeb.MarketingRoutes
    end
  end

  defmacro marketing_routes do
    quote do
      get "/", PageController, :home
      get "/blog", BlogController, :index
      get "/blog/feed.xml", BlogController, :feed
      get "/blog/:slug", BlogController, :show
      get "/features", FeatureController, :index
      get "/features/:slug", FeatureController, :show
      get "/changelog", ChangelogController, :index
      get "/changelog/feed.xml", ChangelogController, :feed
      get "/docs", DocsController, :index
      get "/docs/:category/:subcategory/:slug", DocsController, :show
      get "/docs/:category/:section", DocsController, :section
      get "/docs/:category", DocsController, :category
      get "/terms", LegalController, :terms
      get "/terms/:date", LegalController, :terms
      get "/privacy", LegalController, :privacy
      get "/privacy/:date", LegalController, :privacy
      get "/cookies", LegalController, :cookies
      get "/cookies/:date", LegalController, :cookies
    end
  end
end
