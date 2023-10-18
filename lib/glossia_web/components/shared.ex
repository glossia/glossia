defmodule GlossiaWeb.Components.Shared do
  @moduledoc false

  import GlossiaWeb.Helpers.OpenGraph
  import Phoenix.Controller, only: [get_csrf_token: 0]
  use Phoenix.Component

  attr :class, :string, default: nil

  def glossia_logo(assigns) do
    ~H"""
    <svg
      class={[@class]}
      viewBox="0 0 2204 2204"
      version="1.1"
      xmlns="http://www.w3.org/2000/svg"
      xmlns:xlink="http://www.w3.org/1999/xlink"
    >
      <g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
        <g>
          <rect
            id="Rectangle"
            fill="#C8BEFD"
            fill-rule="nonzero"
            x="0"
            y="0"
            width="2204"
            height="2204"
            rx="491.964"
          >
          </rect>
          <path
            d="M952.458,501.267 L401.458,501.267 C374.287,501.267 352.261,523.293 352.261,550.463 L352.261,555.383 C352.261,582.553 374.287,604.579 401.458,604.579 L952.458,604.579 C979.628,604.579 1001.65,582.553 1001.65,555.383 L1001.65,550.463 C1001.65,523.293 979.628,501.267 952.458,501.267 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M1838.59,727.57 L1213.79,727.57 C1186.62,727.57 1164.6,749.596 1164.6,776.766 L1164.6,781.686 C1164.6,808.857 1186.62,830.883 1213.79,830.883 L1838.59,830.883 C1865.76,830.883 1887.78,808.857 1887.78,781.686 L1887.78,776.766 C1887.78,749.596 1865.76,727.57 1838.59,727.57 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M1474.53,501.267 L1159.68,501.267 C1132.51,501.267 1110.48,523.293 1110.48,550.463 L1110.48,555.383 C1110.48,582.553 1132.51,604.579 1159.68,604.579 L1474.53,604.579 C1501.7,604.579 1523.73,582.553 1523.73,555.383 L1523.73,550.463 C1523.73,523.293 1501.7,501.267 1474.53,501.267 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M1833.67,501.267 L1681.16,501.267 C1653.99,501.267 1631.96,523.293 1631.96,550.463 L1631.96,555.383 C1631.96,582.553 1653.99,604.579 1681.16,604.579 L1833.67,604.579 C1860.84,604.579 1882.86,582.553 1882.86,555.383 L1882.86,550.463 C1882.86,523.293 1860.84,501.267 1833.67,501.267 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M953.051,732.49 L800.542,732.49 C773.372,732.49 751.346,754.516 751.346,781.686 L751.346,786.606 C751.346,813.776 773.372,835.802 800.542,835.802 L953.051,835.802 C980.221,835.802 1002.25,813.776 1002.25,786.606 L1002.25,781.686 C1002.25,754.516 980.221,732.49 953.051,732.49 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M588.404,727.57 L401.458,727.57 C374.287,727.57 352.261,749.596 352.261,776.766 L352.261,781.686 C352.261,808.857 374.287,830.883 401.458,830.883 L588.404,830.883 C615.574,830.883 637.6,808.857 637.6,781.686 L637.6,776.766 C637.6,749.596 615.574,727.57 588.404,727.57 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M555.679,1476.43 L368.733,1476.43 C341.563,1476.43 319.537,1454.4 319.537,1427.23 L319.537,1422.31 C319.537,1395.14 341.563,1373.12 368.733,1373.12 L555.679,1373.12 C582.85,1373.12 604.876,1395.14 604.876,1422.31 L604.876,1427.23 C604.876,1454.4 582.85,1476.43 555.679,1476.43 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M411.16,1129.61 C390.988,1149.78 390.988,1182.49 411.162,1202.66 C431.335,1222.83 464.042,1222.83 484.215,1202.66 L411.16,1129.61 Z M616.751,997.063 L652.092,959.389 L615.602,925.159 L580.224,960.538 L616.751,997.063 Z M761.641,1203.81 L799.316,1239.15 L869.998,1163.8 L832.323,1128.46 L761.641,1203.81 Z M484.215,1202.66 L653.278,1033.59 L580.224,960.538 L411.16,1129.61 L484.215,1202.66 Z M581.41,1034.74 L761.641,1203.81 L832.323,1128.46 L652.092,959.389 L581.41,1034.74 Z"
            id="Shape"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M919.733,1471.51 L767.224,1471.51 C740.053,1471.51 718.027,1449.48 718.027,1422.31 L718.027,1417.39 C718.027,1390.22 740.053,1368.2 767.224,1368.2 L919.733,1368.2 C946.903,1368.2 968.929,1390.22 968.929,1417.39 L968.929,1422.31 C968.929,1449.48 946.903,1471.51 919.733,1471.51 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <polyline
            id="Path"
            stroke="#000000"
            stroke-width="103.312"
            points="797.804 1162.84 966.872 993.768 1147.1 1162.84"
          >
          </polyline>
          <path
            d="M1805.27,1476.43 L1180.47,1476.43 C1153.3,1476.43 1131.28,1454.4 1131.28,1427.23 L1131.28,1422.31 C1131.28,1395.14 1153.3,1373.12 1180.47,1373.12 L1805.27,1373.12 C1832.44,1373.12 1854.46,1395.14 1854.46,1422.31 L1854.46,1427.23 C1854.46,1454.4 1832.44,1476.43 1805.27,1476.43 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <polyline
            id="Path"
            stroke="#000000"
            stroke-width="103.312"
            points="1113.87 1203.09 1282.94 1034.03 1463.17 1203.09"
          >
          </polyline>
          <path
            d="M1441.21,1702.73 L1126.36,1702.73 C1099.19,1702.73 1077.16,1680.71 1077.16,1653.54 L1077.16,1648.62 C1077.16,1621.45 1099.19,1599.42 1126.36,1599.42 L1441.21,1599.42 C1468.39,1599.42 1490.41,1621.45 1490.41,1648.62 L1490.41,1653.54 C1490.41,1680.71 1468.39,1702.73 1441.21,1702.73 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M1800.35,1702.73 L1647.84,1702.73 C1620.67,1702.73 1598.64,1680.71 1598.64,1653.54 L1598.64,1648.62 C1598.64,1621.45 1620.67,1599.42 1647.84,1599.42 L1800.35,1599.42 C1827.52,1599.42 1849.55,1621.45 1849.55,1648.62 L1849.55,1653.54 C1849.55,1680.71 1827.52,1702.73 1800.35,1702.73 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M919.733,1702.73 L368.733,1702.73 C341.563,1702.73 319.537,1680.71 319.537,1653.54 L319.537,1648.62 C319.537,1621.45 341.563,1599.42 368.733,1599.42 L919.733,1599.42 C946.903,1599.42 968.929,1621.45 968.929,1648.62 L968.929,1653.54 C968.929,1680.71 946.903,1702.73 919.733,1702.73 Z"
            id="Path"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
          <path
            d="M1392.2,1132.13 L1355.68,1168.66 L1428.73,1241.71 L1465.26,1205.18 L1392.2,1132.13 Z M1597.79,999.588 L1633.13,961.914 L1596.64,927.683 L1561.26,963.062 L1597.79,999.588 Z M1742.68,1206.33 C1763.49,1225.85 1796.18,1224.8 1815.7,1204 C1835.22,1183.19 1834.17,1150.5 1813.36,1130.98 L1742.68,1206.33 Z M1465.26,1205.18 L1634.32,1036.11 L1561.26,963.062 L1392.2,1132.13 L1465.26,1205.18 Z M1562.45,1037.26 L1742.68,1206.33 L1813.36,1130.98 L1633.13,961.914 L1562.45,1037.26 Z"
            id="Shape"
            fill="#000000"
            fill-rule="nonzero"
          >
          </path>
        </g>
      </g>
    </svg>
    """
  end

  def primer(assigns) do
    ~H"""
    <link phx-track-static rel="stylesheet" href="/primer_live/primer-live.min.css" />
    <script defer phx-track-static type="text/javascript" src="/primer_live/primer-live.min.js">
    </script>
    """
  end

  def head_alpine(assigns) do
    ~H"""
    <script defer src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js">
    </script>
    """
  end

  attr :surface, :string, required: true

  def head_assets(assigns) do
    ~H"""
    <link phx-track-static rel="stylesheet" href="/assets/app.css" />
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
    assigns = assigns
      |> assign(:api_key, Application.get_env(:posthog, :api_key))
      |> assign(:api_url, Application.get_env(:posthog, :api_url))

    ~H"""
    <script :if={@api_key && @api_url}>
      !function(t,e){var o,n,p,r;e.__SV||(window.posthog=e,e._i=[],e.init=function(i,s,a){function g(t,e){var o=e.split(".");2==o.length&&(t=t[o[0]],e=o[1]),t[e]=function(){t.push([e].concat(Array.prototype.slice.call(arguments,0)))}}(p=t.createElement("script")).type="text/javascript",p.async=!0,p.src=s.api_host+"/static/array.js",(r=t.getElementsByTagName("script")[0]).parentNode.insertBefore(p,r);var u=e;for(void 0!==a?u=e[a]=[]:a="posthog",u.people=u.people||[],u.toString=function(t){var e="posthog";return"posthog"!==a&&(e+="."+a),t||(e+=" (stub)"),e},u.people.toString=function(){return u.toString(1)+".people (stub)"},o="capture identify alias people.set people.set_once set_config register register_once unregister opt_out_capturing has_opted_out_capturing opt_in_capturing reset isFeatureEnabled onFeatureFlags getFeatureFlag getFeatureFlagPayload reloadFeatureFlags group updateEarlyAccessFeatureEnrollment getEarlyAccessFeatures getActiveMatchingSurveys getSurveys".split(" "),n=0;n<o.length;n++)g(u,o[n]);e._i.push([i,s,a])},e.__SV=1)}(document,window.posthog||[]);
      posthog.init('<%= @api_key %>',{api_host:'<%= @api_url %>'})
    </script>
    """
  end

  def head_og(assigns) do
    ~H"""
    <% open_graph_metadata = get_open_graph_metadata(assigns) %>
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
    <meta property="og:url" content={Application.get_env(:glossia, :url)} />
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
