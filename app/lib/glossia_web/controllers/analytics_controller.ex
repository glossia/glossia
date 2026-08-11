defmodule GlossiaWeb.AnalyticsController do
  @moduledoc """
  Public, cookieless analytics collection endpoint.

  Accepts a single event from the `@glossia/web` SDK at `POST /v1/collect`,
  with `POST /api/analytics/events` retained for compatibility,
  enriches it with server-only signals (client IP and User-Agent, never stored
  raw), computes the localization gap against the project's target languages,
  and buffers a ClickHouse row.

  Following Plausible's model, the project is resolved by the site domain the
  snippet declares (`data-domain`, sent as `d`), falling back to the page URL
  host or the request origin. The endpoint always responds `202 Accepted`,
  including for unknown domains or malformed payloads. This keeps the SDK
  resilient and avoids leaking which projects collect analytics.
  """

  use GlossiaWeb, :controller

  alias Glossia.Analytics.Client
  alias Glossia.Analytics.Geolocation
  alias Glossia.Analytics.Identity
  alias Glossia.Analytics.Ingestion
  alias Glossia.Analytics.Settings

  def collect(conn, params) do
    try do
      with {:ok, settings} <- fetch_settings(conn, params),
           {:ok, event} <- build_event(conn, params, settings) do
        Ingestion.record_event(event)
      end
    rescue
      _ -> :ok
    end

    conn
    |> put_resp_header("cache-control", "no-store")
    |> resp(202, "")
  end

  defp fetch_settings(conn, params) do
    case resolve_domain(conn, params) do
      "" ->
        {:error, :missing_domain}

      domain ->
        case Settings.fetch_for_collection(domain) do
          nil -> {:error, :unknown_domain}
          settings -> {:ok, settings}
        end
    end
  end

  # The declared `data-domain` is authoritative (a site may be served on many
  # hostnames but reports one canonical domain). Fall back to the page URL host,
  # then the request origin, so a missing attribute still resolves in practice.
  defp resolve_domain(conn, params) do
    [params["d"], host_of(params["u"]), origin_host(conn)]
    |> Enum.map(&to_string/1)
    |> Enum.find("", fn candidate -> candidate != "" end)
  end

  defp host_of(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) -> host
      _ -> ""
    end
  end

  defp host_of(_), do: ""

  defp origin_host(conn) do
    header =
      case get_req_header(conn, "origin") do
        [value | _] -> value
        _ -> conn |> get_req_header("referer") |> List.first()
      end

    host_of(header)
  end

  defp build_event(conn, params, settings) do
    ip = client_ip(conn)
    user_agent = conn |> get_req_header("user-agent") |> List.first() || ""
    languages = client_languages(params, conn)
    target_locales = settings.target_languages || []

    {browser_language, served_locale, has_locale_gap} =
      Client.localize(languages, target_locales)

    %{country: country} =
      if ip, do: Geolocation.lookup(ip), else: %{country: nil}

    url_parts = Client.parse_url(params["u"])
    ref_parts = Client.parse_referrer(params["r"])
    %{device: device, browser: browser, os: os} = Client.parse_user_agent(user_agent)

    {:ok,
     %{
       project_id: settings.project_id,
       visitor_id: Identity.visitor_id(ip || "", user_agent, to_string(settings.project_id)),
       session_id: params["sid"] || "",
       name: event_name(params["n"]),
       hostname: url_parts.hostname,
       pathname: url_parts.pathname,
       referrer: ref_parts.referrer,
       referrer_source: ref_parts.referrer_source,
       country_code: country || "",
       browser_language: browser_language,
       served_locale: served_locale,
       has_locale_gap: has_locale_gap,
       device: device,
       browser: browser,
       os: os,
       screen_width: parse_uint(params["sw"], 0),
       timezone: bounded_string(params["tz"])
     }}
  end

  defp client_languages(params, conn) do
    case Client.parse_languages(params["l"]) do
      [] -> Client.parse_languages(accept_language(conn))
      preferred -> preferred
    end
  end

  defp accept_language(conn) do
    conn |> get_req_header("accept-language") |> List.first() || ""
  end

  # The first X-Forwarded-For hop is the originating client when behind a load
  # balancer. We validate it parses as an IP before trusting it, and fall back to
  # the socket peer (`conn.remote_ip`) otherwise.
  defp client_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [xff | _] when is_binary(xff) and xff != "" ->
        xff
        |> String.split(",")
        |> List.first()
        |> String.trim()
        |> validate_ip()

      _ ->
        case :inet.ntoa(conn.remote_ip) do
          charlist when is_list(charlist) -> List.to_string(charlist)
          _ -> nil
        end
    end
  end

  defp validate_ip(candidate) do
    case :inet.parse_address(to_charlist(candidate)) do
      {:ok, _} -> candidate
      {:error, _} -> nil
    end
  end

  defp event_name(nil), do: "pageview"
  defp event_name(""), do: "pageview"
  defp event_name(name) when is_binary(name), do: String.slice(name, 0, 64)

  defp parse_uint(nil, default), do: default
  defp parse_uint(value, _default) when is_integer(value) and value >= 0, do: value

  defp parse_uint(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {n, _} when n >= 0 -> n
      _ -> default
    end
  end

  defp bounded_string(nil), do: ""
  defp bounded_string(value) when is_binary(value), do: String.slice(value, 0, 64)
end
