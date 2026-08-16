defmodule Glossia.Analytics.Geolocation do
  @moduledoc """
  Country resolution for analytics events.

  Noop by default, so the application runs and compiles without any GeoIP
  dependency; country is recorded as an empty string until an adapter is
  configured. The IP address itself is never persisted; only the resolved
  ISO 3166-1 alpha-2 country code (or an empty string) lands on the event row.

  Three adapters are shipped:

    * `Glossia.Analytics.Geolocation.Ipapi` — used in production when no
      MaxMind database is configured. Looks the country up against a public
      IP-geolocation service, memoizing results so the controller never blocks
      on the network twice for the same IP.
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
    hot path, lookups are memoized for 24 hours in the Cachex cache owned by
    `Glossia.Analytics.Geolocation.Ipapi.Cache` — long enough that repeat
    visitors are served instantly, short enough that stale results (e.g. a
    relocated mobile carrier) correct themselves within a day. Concurrent
    misses for the same IP are collapsed by Cachex into a single request, so
    a burst of events from one visitor cannot fan out into a burst of
    upstream calls.

    The lookup never raises: a timeout, a non-200 response, an unexpected
    payload, or a private/loopback IP all resolve to `%{country: nil}` so
    ingestion can never fail on geolocation.
    """
    @behaviour Glossia.Analytics.Geolocation

    import Bitwise

    @endpoint "https://api.ipapi.is"

    @impl true
    def lookup(ip) do
      cond do
        not is_binary(ip) or ip == "" ->
          %{country: nil}

        reserved_ip?(ip) ->
          %{country: nil}

        true ->
          %{country: Glossia.Analytics.Geolocation.Ipapi.Cache.fetch(ip, &resolve/1)}
      end
    end

    # Failures are returned but deliberately not committed, so a blip upstream
    # does not pin `nil` to an IP for the next 24 hours.
    defp resolve(ip) do
      case request(ip) do
        {:ok, country} -> {:commit, country}
        :error -> {:ignore, nil}
      end
    end

    defp request(ip) do
      case Req.get(@endpoint,
             params: [q: ip],
             receive_timeout: 1_000,
             connect_timeout: 1_000,
             retry: false
           ) do
        {:ok, %Req.Response{status: 200, body: body}} when is_map(body) ->
          code = body["cc"] || get_in(body, ["location", "country_code"]) || body["country_code"]

          if is_binary(code) and byte_size(code) == 2,
            do: {:ok, String.upcase(code)},
            else: :error

        _ ->
          :error
      end
    rescue
      _ -> :error
    catch
      _, _ -> :error
    end

    # Reserved ranges have no useful country and `ipapi.is` would refuse to
    # answer them anyway, so short-circuit them rather than spend a request we
    # know is wasted. Parsing the address beats prefix matching on the string:
    # ULAs are randomly generated within fc00::/7 (`fd3a:…` is as common as
    # `fd00:…`) and CGNAT space is increasingly what mobile carriers hand out.
    defp reserved_ip?(ip) do
      case :inet.parse_address(to_charlist(ip)) do
        {:ok, address} -> reserved_address?(address)
        # Unparseable input is never worth a round-trip.
        {:error, _} -> true
      end
    end

    # IPv4-mapped IPv6 (`::ffff:10.0.0.1`) is classified as the IPv4 address
    # it wraps, so mapped private space is caught too.
    defp reserved_address?({0, 0, 0, 0, 0, 0xFFFF, ab, cd}),
      do: reserved_address?({ab >>> 8, ab &&& 0xFF, cd >>> 8, cd &&& 0xFF})

    defp reserved_address?({0, _, _, _}), do: true
    defp reserved_address?({10, _, _, _}), do: true
    defp reserved_address?({127, _, _, _}), do: true
    defp reserved_address?({169, 254, _, _}), do: true
    defp reserved_address?({192, 168, _, _}), do: true
    defp reserved_address?({172, b, _, _}) when b in 16..31, do: true
    # 100.64.0.0/10, carrier-grade NAT.
    defp reserved_address?({100, b, _, _}) when b in 64..127, do: true
    # Multicast (224/4) and reserved/broadcast (240/4).
    defp reserved_address?({a, _, _, _}) when a >= 224, do: true
    # `::` and `::1`.
    defp reserved_address?({0, 0, 0, 0, 0, 0, 0, n}) when n in [0, 1], do: true
    # fc00::/7, unique local.
    defp reserved_address?({a, _, _, _, _, _, _, _}) when (a &&& 0xFE00) == 0xFC00, do: true
    # fe80::/10, link local.
    defp reserved_address?({a, _, _, _, _, _, _, _}) when (a &&& 0xFFC0) == 0xFE80, do: true
    # ff00::/8, multicast.
    defp reserved_address?({a, _, _, _, _, _, _, _}) when (a &&& 0xFF00) == 0xFF00, do: true
    defp reserved_address?(_address), do: false

    defmodule Cache do
      @moduledoc false

      # Cachex cache for IP -> country, keyed by the address string. The same
      # IP is looked up many times by one visitor session (and across sessions
      # behind a shared NAT), so a 24h TTL keeps the hot path off the network
      # without holding onto stale data for long.
      #
      # Unlike the domain cache, the key space here is attacker-influenced and
      # unbounded — every unique client IP that ever reaches the ingestion
      # endpoint would otherwise earn a permanent row. The size limit below
      # bounds it explicitly; the janitor reclaims expired rows in between.

      import Cachex.Spec

      @cache __MODULE__
      @ttl :timer.hours(24)
      @max_size 100_000

      # `:name` lets a test start its own scoped instance rather than share the
      # application-wide one.
      def child_spec(opts) do
        name = Keyword.get(opts, :name, @cache)

        Supervisor.child_spec(
          {Cachex,
           name: name,
           expiration: expiration(default: @ttl),
           hooks: [hook(module: Cachex.Limit.Scheduled, args: {@max_size, [], []})]},
          id: name
        )
      end

      @doc """
      Returns the cached country for `ip`, invoking `resolver` on a miss.

      Cachex routes concurrent misses for the same key through a single
      resolver call, so a burst of events from one visitor makes one request.
      """
      def fetch(ip, resolver, cache \\ @cache) do
        case Cachex.fetch(cache, ip, resolver) do
          {status, country} when status in [:ok, :commit, :ignore] -> country
          _error -> nil
        end
      end
    end
  end
end
