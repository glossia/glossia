defmodule Glossia.Analytics.Geolocation do
  @moduledoc """
  Country resolution for analytics events.

  Noop by default, so the application runs and compiles without any GeoIP
  dependency; country is recorded as an empty string until an adapter is
  configured. The IP address itself is never persisted; only the resolved
  ISO 3166-1 alpha-2 country code (or an empty string) lands on the event row.

  To enable country data, set the adapter to a MaxMind-backed module and point
  it at a GeoLite2-Country `.mmdb`:

      config :glossia, Glossia.Analytics,
        geolocation: [
          adapter: Glossia.Analytics.Geolocation.Maxmind,
          database_path: "/etc/glossia/GeoLite2-Country.mmdb"
        ]

  The shipped `Glossia.Analytics.Geolocation.Maxmind` is a guarded reference
  implementation that activates once a GeoIP library (for example `geolix` with
  an MMDB adapter) is added to the project and registered under the
  `:glossia_analytics_country` database id.
  """

  @callback lookup(ip :: String.t()) :: %{country: String.t() | nil}

  @doc """
  Resolves the country code for an IP address, returning `%{country: nil}` when
  no adapter or database is configured or the lookup fails.
  """
  def lookup(ip) when is_binary(ip) do
    Glossia.Analytics.Config.geolocation_adapter().lookup(ip)
  end

  defmodule Noop do
    @moduledoc false
    @behaviour Glossia.Analytics.Geolocation

    @impl true
    def lookup(_ip), do: %{country: nil}
  end

  defmodule Maxmind do
    @moduledoc """
    MaxMind GeoLite2 country resolution via `geolix`.

    Safe to compile and call without the `:geolix` dependency or the database
    present: it falls back to `%{country: nil}` so ingestion never fails on
    environments that have not yet configured GeoIP.
    """
    @behaviour Glossia.Analytics.Geolocation

    # `Geolix` is an optional, operator-provided dependency; the guarded call
    # below is inert until it is added, so silence the undefined-module warning.
    @compile {:no_warn_undefined, Geolix}

    @impl true
    def lookup(ip) do
      if Code.ensure_loaded?(Geolix) do
        try do
          case Geolix.lookup(to_charlist(ip), where: :glossia_analytics_country) do
            %{country: %{iso_code: code}} when is_binary(code) and code != "" ->
              %{country: code}

            _ ->
              %{country: nil}
          end
        rescue
          _ -> %{country: nil}
        end
      else
        %{country: nil}
      end
    end
  end
end
