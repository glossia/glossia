defmodule GlossiaWeb.MarketingComponents do
  use Boundary, deps: [GlossiaWeb.SEO]

  use GlossiaWeb.SEO

  @moduledoc """
  It provides marketing components
  """
  use Boundary, deps: [GlossiaWeb.Gettext]

  use Phoenix.Component

  def meta(assigns) do
    ~H"""
    <title><%= get_seo_metadata(@conn)[:title] %></title>
    <meta property="article:published_time" content="2022-09-07T00:00:00+00:00" />
    <meta name="description" content={get_seo_metadata(@conn)[:description]} />
    <meta name="author" content={Application.fetch_env!(:glossia, :seo_metadata).author} />
    <!-- Open graph -->
    <meta property="og:title" content={get_seo_metadata(@conn)[:title]} />
    <meta property="og:description" content={get_seo_metadata(@conn)[:description]} />
    <meta property="og:type" content="article" />
    <meta property="og:site_name" content="Pedro Piñera" />
    <meta property="og:url" content={Phoenix.Controller.current_url(@conn)} />
    <meta property="og:image" content={image(@conn)} />
    <!-- Twitter -->
    <meta name="twitter:card" content="summary" />
    <meta name="twitter:title" content={get_seo_metadata(@conn)[:title]} />
    <meta name="twitter:description" content={get_seo_metadata(@conn)[:description]} />
    <meta name="twitter:image" content={image(@conn)} />
    <meta
      name="twitter:site"
      content={Application.fetch_env!(:glossia, :seo_metadata).twitter_handle}
    />
    <meta property="twitter:domain" content={Application.fetch_env!(:glossia, :seo_metadata).domain} />
    <meta
      property="twitter:url"
      content={Application.fetch_env!(:glossia, :seo_metadata).base_url |> URI.to_string()}
    />
    <!-- Favicon -->
    <link rel="shortcut icon" href={static_asset_url("/favicons/favicon.ico")} />
    <link
      rel="apple-touch-icon"
      sizes="180x180"
      href={static_asset_url("/favicon/apple-touch-icon.png")}
    />
    <link
      rel="icon"
      type="image/png"
      sizes="32x32"
      href={static_asset_url("/favicon/favicon-32x32.png")}
    />
    <link
      rel="icon"
      type="image/png"
      sizes="16x16"
      href={static_asset_url("/favicon/favicon-16x16.png")}
    />
    <link rel="manifest" href={static_asset_url("/favicon/site.webmanifest")} />
    <meta name="msapplication-TileColor" content="#da532c" />
    <meta name="theme-color" content="#ffffff" />
    """
  end

  defp image(_conn) do
    # metadata_image = get_metadata(conn)[:image]
    static_asset_url("/images/avatar.jpeg")
  end

  defp static_asset_url(path) do
    Application.fetch_env!(:glossia, :seo_metadata).base_url |> URI.merge(path) |> URI.to_string()
  end
end
