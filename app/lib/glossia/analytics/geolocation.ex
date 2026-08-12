defmodule Glossia.Analytics.Geolocation do
  @moduledoc """
  Country resolution for analytics events.

  Noop by default, so the application runs and compiles without any GeoIP
  dependency; country is recorded as an empty string until an adapter is
  configured. The IP address itself is never persisted; only the resolved
  ISO 3166-1 alpha-2 country code (or an empty string) lands on the event row.

  Three adapters are shipped:

    * `Glossia.Analytics.Geolocation.Ipapi` — the default. Looks the country
      up against a public IP-geolocation service. Results are cached in ETS
      so the controller never blocks on the network twice for the same IP.
    * `Glossia.Analytics.Geolocation.Maxmind` — local, offline lookups against
      a MaxMind GeoLite2-Country `.mmdb` via `geolix`. Activate by setting
      `GLOSSIA_GEOIP_DATABASE_PATH` to the path of the database and making
      sure `:geolix` plus an MMDB adapter are added to the project.
    * `Glossia.Analytics.Geolocation.Noop` — returns `nil` for every IP. Used
      in test environments and as a safety net when the configured adapter
      cannot be reached.

  Switch between them with the `:geolocation` key on
  `config :glossia, Glossia.Analytics`:

      config :glossia, Glossia.Analytics,
        geolocation: [adapter: Glossia.Analytics.Geolocation.Ipapi]

      config :glossia, Glossia.Analytics,
        geolocation: [
          adapter: Glossia.Analytics.Geolocation.Maxmind,
          database_path: "/etc/glossia/GeoLite2-Country.mmdb"
        ]
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

  defmodule Ipapi do
    @moduledoc """
    Network-backed country resolution via the public `ipapi.is` service.

    The endpoint is unauthenticated, has no published rate limit that would
    affect a single application's analytics traffic, and returns the ISO
    3166-1 alpha-2 country code we persist. To avoid the round-trip on the
    hot path, lookups are memoized in a small public ETS table owned by
    `Glossia.Analytics.Geolocation.Ipapi.Cache` for 24 hours — long enough
    that repeat visitors are served instantly, short enough that stale
    results (e.g. a relocated mobile carrier) correct themselves within a
    day.

    The lookup never raises: a timeout, a non-200 response, an unexpected
    payload, or a private/loopback IP all resolve to `%{country: nil}` so
    ingestion can never fail on geolocation.
    """
    @behaviour Glossia.Analytics.Geolocation

    @endpoint "https://api.ipapi.is"
    # Private, loopback and link-local ranges have no useful country and
    # `ipapi.is` would refuse to answer them anyway. Short-circuit them so
    # we never make a request we know will be wasted.
    @private_prefixes ["127.", "::1", "0.", "10.", "192.168.", "169.254.", "172.16.",
                       "172.17.", "172.18.", "172.19.", "172.20.", "172.21.", "172.22.",
                       "172.23.", "172.24.", "172.25.", "172.26.", "172.27.", "172.28.",
                       "172.29.", "172.30.", "172.31.", "fc00:", "fd00:", "fe80:"]

    @impl true
    def lookup(ip) do
      cond do
        not is_binary(ip) or ip == "" ->
          %{country: nil}

        private_ip?(ip) ->
          %{country: nil}

        true ->
          case Glossia.Analytics.Geolocation.Ipapi.Cache.get(ip) do
            {:hit, country} ->
              %{country: country}

            :miss ->
              case fetch(ip) do
                {:ok, country} ->
                  Glossia.Analytics.Geolocation.Ipapi.Cache.put(ip, country)
                  %{country: country}

                :error ->
                  %{country: nil}
              end
          end
      end
    end

    defp fetch(ip) do
      case Req.get("#{@endpoint}/#{URI.encode(ip)}",
             receive_timeout: 1_000,
             connect_timeout: 1_000,
             retry: false
           ) do
        {:ok, %Req.Response{status: 200, body: body}} when is_map(body) ->
          code = get_in(body, ["location", "country_code"]) || body["country_code"]
          if is_binary(code) and byte_size(code) == 2, do: {:ok, code}, else: :error

        _ ->
          :error
      end
    rescue
      _ -> :error
    catch
      _, _ -> :error
    end

    defp private_ip?(ip) do
      Enum.any?(@private_prefixes, &String.starts_with?(ip, &1))
    end

    defmodule Cache do
      @moduledoc false

      # Tiny read-optimized ETS cache for IP -> country, keyed by the
      # address string. IPs are looked up many times by the same visitor
      # session (and across sessions that share a NAT), so a 24h TTL keeps
      # the hot path off the network without holding onto stale data for
      # long. The table is public, so reads and the occasional eviction
      # happen directly without a GenServer round-trip.

      use GenServer

      @table __MODULE__
      @ttl :timer.hours(24)

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      def get(key) do
        now = System.monotonic_time(:millisecond)

        case :ets.lookup(@table, key) do
          [{^key, entry, expires_at}] when expires_at > now ->
            {:hit, entry}

          _ ->
            :miss
        end
      end

      def put(key, entry) do
        :ets.insert(@table, {key, entry, System.monotonic_time(:millisecond) + @ttl})
        entry
      end

      @impl true
      def init(_opts) do
        if :ets.whereis(@table) == :undefined do
          :ets.new(@table, [:set, :named_table, :public, read_concurrency: true])
        end

        {:ok, %{}}
      end
    end
  end
end
