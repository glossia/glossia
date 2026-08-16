defmodule Glossia.Analytics.GeolocationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Mimic

  alias Glossia.Analytics.Geolocation

  test "the Noop adapter resolves no country" do
    assert Geolocation.Noop.lookup("203.0.113.1") == %{country: nil}
  end

  test "the Maxmind adapter falls back to nil when geolix is not loaded" do
    refute Code.ensure_loaded?(Geolix)
    assert Geolocation.Maxmind.lookup("203.0.113.1") == %{country: nil}
  end

  test "lookup/1 dispatches to the configured adapter (Noop in test)" do
    assert Geolocation.lookup("203.0.113.1") == %{country: nil}
  end

  describe "Ipapi adapter" do
    alias Glossia.Analytics.Geolocation.Ipapi

    # `Cachex.fetch/3` runs the resolver in its own courier process, so the
    # `Req` stubs have to be visible outside the test process.
    setup :set_mimic_global
    setup :verify_on_exit!

    setup do
      Cachex.clear(Ipapi.Cache)
      :ok
    end

    test "treats empty IPs as unknown" do
      assert Ipapi.lookup("") == %{country: nil}
    end

    test "skips the network for reserved addresses" do
      reserved = [
        "127.0.0.1",
        "10.0.0.5",
        "192.168.1.1",
        "172.16.0.1",
        "172.31.255.254",
        "169.254.1.1",
        "0.0.0.0",
        "224.0.0.1",
        # Carrier-grade NAT, handed out by mobile carriers.
        "100.64.0.1",
        "::1",
        "::",
        "fe80::1",
        # Unique local addresses are random within fc00::/7, so the common
        # case is not the `fd00:` prefix.
        "fd3a:9c2b:1::1",
        "fc00::1",
        # IPv4-mapped private space.
        "::ffff:10.0.0.1"
      ]

      for ip <- reserved do
        assert Ipapi.lookup(ip) == %{country: nil}, "expected #{ip} to short-circuit"
      end
    end

    test "skips the network for unparseable input" do
      assert Ipapi.lookup("not-an-ip") == %{country: nil}
    end

    test "still resolves public addresses that sit near reserved ranges" do
      # `172.160.0.1` is public despite sharing a prefix with 172.16.0.0/12,
      # and `100.128.0.1` sits just past the CGNAT block.
      for ip <- ["172.160.0.1", "100.128.0.1", "2606:4700::1111"] do
        expect(Req, :get, fn _url, _opts ->
          {:ok, %Req.Response{status: 200, body: %{"location" => %{"country_code" => "US"}}}}
        end)

        assert Ipapi.lookup(ip) == %{country: "US"}, "expected #{ip} to be looked up"
      end
    end

    test "reports a non-200 response and returns nil" do
      ip = "203.0.113.10"

      expect(Req, :get, fn _url, _opts ->
        {:ok, %Req.Response{status: 429, body: %{"error" => "rate limit"}}}
      end)

      log = capture_log(fn -> assert Ipapi.lookup(ip) == %{country: nil} end)

      assert log =~ "Analytics country lookup failed: unexpected_status"
    end

    test "uses the documented query and returns the country code from the free response" do
      ip = "203.0.113.20"

      test_pid = self()

      expect(Req, :get, fn url, opts ->
        assert %Req.Request{} = Req.new([url: url] ++ opts)
        send(test_pid, {:request, url, opts})
        {:ok, %Req.Response{status: 200, body: %{"cc" => "us"}}}
      end)

      assert Ipapi.lookup(ip) == %{country: "US"}
      assert_received {:request, "https://api.ipapi.is", opts}
      assert opts[:params] == [q: ip]
      assert opts[:connect_options] == [timeout: 1_000]
      # Second call must be served from the cache, no extra HTTP request.
      assert Ipapi.lookup(ip) == %{country: "US"}
      refute_received {:request, _, _}
    end

    test "reports request exceptions without exposing the visitor address" do
      ip = "203.0.113.25"

      expect(Req, :get, fn _url, _opts -> raise ArgumentError, "invalid request option" end)

      log = capture_log(fn -> assert Ipapi.lookup(ip) == %{country: nil} end)

      assert log =~ "Analytics country lookup failed: request_exception"
      refute log =~ ip
    end

    test "ignores responses that do not carry a 2-letter country code" do
      ip = "203.0.113.30"

      expect(Req, :get, fn _url, _opts ->
        {:ok, %Req.Response{status: 200, body: %{"location" => %{"country_code" => nil}}}}
      end)

      assert Ipapi.lookup(ip) == %{country: nil}
    end

    test "does not cache failures, so a later request can still resolve" do
      ip = "203.0.113.40"

      expect(Req, :get, fn _url, _opts -> {:ok, %Req.Response{status: 500, body: %{}}} end)
      assert Ipapi.lookup(ip) == %{country: nil}

      expect(Req, :get, fn _url, _opts ->
        {:ok, %Req.Response{status: 200, body: %{"location" => %{"country_code" => "DE"}}}}
      end)

      assert Ipapi.lookup(ip) == %{country: "DE"}
    end

    test "collapses concurrent misses for the same IP into one request" do
      ip = "203.0.113.50"
      test_pid = self()

      # A second call would raise, since only one is expected.
      expect(Req, :get, fn _url, _opts ->
        send(test_pid, :hit)
        Process.sleep(50)
        {:ok, %Req.Response{status: 200, body: %{"location" => %{"country_code" => "FR"}}}}
      end)

      results =
        1..10
        |> Task.async_stream(fn _ -> Ipapi.lookup(ip) end, max_concurrency: 10)
        |> Enum.map(fn {:ok, result} -> result end)

      assert Enum.all?(results, &(&1 == %{country: "FR"}))
      assert_received :hit
      refute_received :hit
    end
  end
end
