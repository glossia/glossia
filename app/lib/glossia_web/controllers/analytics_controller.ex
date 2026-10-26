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
  alias Glossia.Analytics.Config
  alias Glossia.Analytics.Country
  alias Glossia.Analytics.Geolocation
  alias Glossia.Analytics.Identity
  alias Glossia.Analytics.Ingestion
  alias Glossia.Analytics.Settings
  alias GlossiaWeb.ClientIP

  require Logger

  def collect(conn, params) do
    try do
      with {:ok, settings} <- fetch_settings(conn, params),
           {:ok, event} <- build_event(conn, params, settings) do
        Ingestion.record_event(event)
      end
    rescue
      exception ->
        Logger.error("Analytics collection failed",
          error_type: inspect(exception.__struct__),
          stacktrace: Exception.format_stacktrace(__STACKTRACE__)
        )

        :ok
    catch
      kind, reason ->
        Logger.error("Analytics collection failed",
          error_type: if(is_atom(reason), do: Atom.to_string(reason), else: "unknown"),
          failure_kind: kind
        )

        :ok
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
    ip = ClientIP.value(conn)
    user_agent = conn |> get_req_header("user-agent") |> List.first() || ""
    languages = client_languages(params, conn)

    target_locales =
      (settings.target_languages || []) ++
        Client.parse_languages(bounded_string(params["al"], 2_048))

    {browser_language, served_locale, has_locale_gap} =
      Client.localize(languages, target_locales, bounded_string(params["sl"]))

    country = cloudflare_country(conn) || lookup_country(ip)

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
       selected_locale: selected_locale(params["cl"]),
       has_locale_gap: has_locale_gap,
       device: device,
       browser: browser,
       os: os,
       screen_width: parse_uint(params["sw"], 0),
       timezone: bounded_string(params["tz"])
     }}
  end

  # This is enabled only for deployments whose edge authenticates Cloudflare
  # or strips untrusted copies of CF-IPCountry. Header presence (including
  # CF-Connecting-IP / CF-Ray) by itself is not proof of provenance.
  defp cloudflare_country(conn) do
    with true <- Config.trust_cloudflare_country_header?(),
         [value] <- get_req_header(conn, "cf-ipcountry"),
         value <- String.trim(value),
         2 <- byte_size(value) do
      # ISO validation excludes Cloudflare's XX (unknown) and T1 (Tor) values.
      Country.code(value)
    else
      _ -> nil
    end
  end

  defp lookup_country(ip) when is_binary(ip) do
    %{country: country} = Geolocation.lookup(ip)
    country
  end

  defp lookup_country(_ip), do: nil

  defp client_languages(params, conn) do
    case Client.parse_languages(params["l"]) do
      [] -> Client.parse_languages(accept_language(conn))
      preferred -> preferred
    end
  end

  defp selected_locale(value) when is_binary(value) and byte_size(value) <= 64 do
    value = String.trim(value)

    if Regex.match?(~r/^[a-zA-Z]{2,8}(?:-[a-zA-Z0-9]{1,8})*$/, value) do
      value |> Client.parse_languages() |> List.first() || ""
    else
      ""
    end
  end

  defp selected_locale(_), do: ""

  defp accept_language(conn) do
    conn |> get_req_header("accept-language") |> List.first() || ""
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

  defp bounded_string(value, limit \\ 64)
  defp bounded_string(value, limit) when is_binary(value), do: String.slice(value, 0, limit)
  defp bounded_string(_, _limit), do: ""
end
