defmodule Glossia.Foundation.Application.Web.Components.Shared do
  import Glossia.Foundation.Application.Web.Helpers.OpenGraph

  @moduledoc """
  A set of components that are shared across all the layouts
  """

  # Modules
  import Phoenix.Controller,
    only: [get_csrf_token: 0]

  use Phoenix.Component

  def head_alpine(assigns) do
    ~H"""
    <script defer src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js">
    </script>
    """
  end

  attr :surface, :string, required: true

  def head_assets(assigns) do
    ~H"""
    <link phx-track-static rel="stylesheet" href={"/assets/#{@surface}.css"} />
    <script defer phx-track-static type="text/javascript" src={"/assets/#{@surface}.js"}>
    </script>
    """
  end

  def head_base(assigns) do
    ~H"""
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="csrf-token" content={get_csrf_token()} />
    """
  end

  def head_posthog(assigns) do
    ~H"""
    <script>
      !function(t,e){var o,n,p,r;e.__SV||(window.posthog=e,e._i=[],e.init=function(i,s,a){function g(t,e){var o=e.split(".");2==o.length&&(t=t[o[0]],e=o[1]),t[e]=function(){t.push([e].concat(Array.prototype.slice.call(arguments,0)))}}(p=t.createElement("script")).type="text/javascript",p.async=!0,p.src=s.api_host+"/static/array.js",(r=t.getElementsByTagName("script")[0]).parentNode.insertBefore(p,r);var u=e;for(void 0!==a?u=e[a]=[]:a="posthog",u.people=u.people||[],u.toString=function(t){var e="posthog";return"posthog"!==a&&(e+="."+a),t||(e+=" (stub)"),e},u.people.toString=function(){return u.toString(1)+".people (stub)"},o="capture identify alias people.set people.set_once set_config register register_once unregister opt_out_capturing has_opted_out_capturing opt_in_capturing reset isFeatureEnabled onFeatureFlags getFeatureFlag getFeatureFlagPayload reloadFeatureFlags group updateEarlyAccessFeatureEnrollment getEarlyAccessFeatures getActiveMatchingSurveys getSurveys".split(" "),n=0;n<o.length;n++)g(u,o[n]);e._i.push([i,s,a])},e.__SV=1)}(document,window.posthog||[]);
      posthog.init('phc_l4rCZ3nesxSCsIxj5azUb7HxDHNHlUZXmWvobmWZ3JZ',{api_host:'https://eu.posthog.com'})
    </script>
    """
  end

  def head_og(assigns) do
    ~H"""
    <% open_graph_metadata = get_open_graph_metadata(@conn.assigns) %>
    <title><%= open_graph_metadata[:title] %></title>
    <meta property="article:published_time" content="2022-09-07T00:00:00+00:00" />
    <meta name="description" content={open_graph_metadata[:description]} />
    <meta name="author" content={Application.fetch_env!(:glossia, :open_graph_metadata).author} />
    <meta name="keywords" content={open_graph_metadata[:keywords] |> Enum.join(",")} />
    <!-- Open graph -->
    <meta property="og:title" content={open_graph_metadata[:title]} />
    <meta property="og:description" content={open_graph_metadata[:description]} />
    <meta property="og:type" content="article" />
    <meta property="og:site_name" content="Pedro Piñera" />
    <meta property="og:url" content={Phoenix.Controller.current_url(@conn)} />
    <meta property="og:image" content="/images/logo.jpg" />
    <!-- Twitter -->
    <meta name="twitter:card" content="summary" />
    <meta name="twitter:title" content={open_graph_metadata[:title]} />
    <meta name="twitter:description" content={open_graph_metadata[:description]} />
    <meta name="twitter:image" content="/images/logo.jpg" />
    <meta
      name="twitter:site"
      content={Application.fetch_env!(:glossia, :open_graph_metadata).twitter_handle}
    />
    <meta
      property="twitter:domain"
      content={Application.fetch_env!(:glossia, :open_graph_metadata).domain}
    />
    <meta
      property="twitter:url"
      content={Application.fetch_env!(:glossia, :open_graph_metadata).base_url |> URI.to_string()}
    />
    <!-- Favicon -->
    <link href="/favicon.ico" rel="icon" type="image/x-icon" />
    <link rel="shortcut icon" href="/favicon.ico" />
    <link rel="apple-touch-icon" sizes="180x180" href="/favicon/apple-touch-icon.png" />
    <link rel="icon" type="image/png" sizes="32x32" href="/favicon/favicon-32x32.png" />
    <link rel="icon" type="image/png" sizes="16x16" href="/favicon/favicon-16x16.png" />
    <link rel="manifest" href="/favicon/site.webmanifest" />
    <meta name="msapplication-TileColor" content="#da532c" />
    <meta name="theme-color" content="#ffffff" />
    """
  end
end
