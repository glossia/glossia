defmodule Glossia.Analytics.GeolocationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Mimic

  alias Glossia.Analytics.Geolocation
  alias Glossia.Analytics.Geolocation.Ipapi

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
    # The adapter owns the resolver, which runs in Cachex's courier process.
    setup :set_mimic_global
    setup :verify_on_exit!

    setup do
      cache = :"test_geo_cache_#{:erlang.unique_integer([:positive])}"
      start_supervised!({Ipapi.Cache, name: cache})
      %{cache: cache}
    end

    test "treats empty IPs as unknown", %{cache: cache} do
      assert Ipapi.lookup("", cache) == %{country: nil}
    end

    test "skips the network for reserved addresses", %{cache: cache} do
      reserved = [
        "127.0.0.1",
        "10.0.0.5",
        "192.168.1.1",
        "172.16.0.1",
        "172.31.255.254",
        "169.254.1.1",
        "0.0.0.0",
        "224.0.0.1",
        "100.64.0.1",
        "::1",
        "::",
        "fe80::1",
        "fd3a:9c2b:1::1",
        "fc00::1",
        "::ffff:10.0.0.1"
      ]

      for ip <- reserved do
        assert Ipapi.lookup(ip, cache) == %{country: nil}, "expected #{ip} to short-circuit"
      end
    end

    test "skips the network for unparseable input", %{cache: cache} do
      assert Ipapi.lookup("not-an-ip", cache) == %{country: nil}
    end

    test "still resolves public addresses that sit near reserved ranges", %{cache: cache} do
      for ip <- ["172.160.0.1", "100.128.0.1", "2606:4700::1111"] do
        expect(Req, :get, fn _url, _opts ->
          {:ok, %Req.Response{status: 200, body: %{"location" => %{"country_code" => "US"}}}}
        end)

        assert Ipapi.lookup(ip, cache) == %{country: "US"}, "expected #{ip} to be looked up"
      end
    end

    test "reports a non-200 response and returns nil", %{cache: cache} do
      expect(Req, :get, fn _url, _opts ->
        {:ok, %Req.Response{status: 429, body: %{"error" => "rate limit"}}}
      end)

      log = capture_log(fn -> assert Ipapi.lookup("203.0.113.10", cache) == %{country: nil} end)
      assert log =~ "Analytics country lookup failed: unexpected_status"
    end

    test "uses the documented query and resolves the real free-tier response", %{cache: cache} do
      test_pid = self()

      expect(Req, :get, fn url, opts ->
        assert %Req.Request{} = Req.new([url: url] ++ opts)
        send(test_pid, {:request, url, opts})

        {:ok,
         %Req.Response{
           status: 200,
           body: %{
             "ip" => "8.8.8.8",
             "is_bogon" => false,
             "company" => "Google LLC",
             "asn" => "AS15169 Google LLC",
             "city" => "Mountain View",
             "region" => "California",
             "country" => "United States",
             "lat" => 37.38605,
             "lon" => -122.08385,
             "timezone" => "America/Los_Angeles",
             "docs" => "https://ipapi.is/free-tier.html?ref=api"
           }
         }}
      end)

      assert Ipapi.lookup("8.8.8.8", cache) == %{country: "US"}
      assert_received {:request, "https://api.ipapi.is", opts}
      assert opts[:params] == [q: "8.8.8.8"]
      assert opts[:connect_options] == [timeout: 1_000]
      assert Ipapi.lookup("8.8.8.8", cache) == %{country: "US"}
      refute_received {:request, _, _}
    end

    test "continues to accept country-code responses", %{cache: cache} do
      bodies = [%{"cc" => "us"}, %{"country_code" => "US"}, %{"country" => "US"}]

      for {body, index} <- Enum.with_index(bodies, 1) do
        ip = "203.0.113.#{index}"
        expect(Req, :get, fn _url, _opts -> {:ok, %Req.Response{status: 200, body: body}} end)
        assert Ipapi.lookup(ip, cache) == %{country: "US"}
      end
    end

    test "reports request exceptions without exposing the visitor address", %{cache: cache} do
      ip = "203.0.113.25"
      expect(Req, :get, fn _url, _opts -> raise ArgumentError, "invalid request option" end)
      log = capture_log(fn -> assert Ipapi.lookup(ip, cache) == %{country: nil} end)
      assert log =~ "Analytics country lookup failed: request_exception"
      refute log =~ ip
    end

    test "ignores unknown countries", %{cache: cache} do
      expect(Req, :get, fn _url, _opts ->
        {:ok, %Req.Response{status: 200, body: %{"country" => "Atlantis"}}}
      end)

      assert Ipapi.lookup("203.0.113.30", cache) == %{country: nil}
    end

    test "does not cache failures, so a later request can still resolve", %{cache: cache} do
      ip = "203.0.113.40"
      expect(Req, :get, fn _url, _opts -> {:ok, %Req.Response{status: 500, body: %{}}} end)
      assert Ipapi.lookup(ip, cache) == %{country: nil}

      expect(Req, :get, fn _url, _opts ->
        {:ok, %Req.Response{status: 200, body: %{"country" => "Germany"}}}
      end)

      assert Ipapi.lookup(ip, cache) == %{country: "DE"}
    end

    test "collapses concurrent misses for the same IP into one request", %{cache: cache} do
      test_pid = self()

      expect(Req, :get, fn _url, _opts ->
        send(test_pid, :hit)
        Process.sleep(50)
        {:ok, %Req.Response{status: 200, body: %{"country" => "France"}}}
      end)

      results =
        1..10
        |> Task.async_stream(fn _ -> Ipapi.lookup("203.0.113.50", cache) end, max_concurrency: 10)
        |> Enum.map(fn {:ok, result} -> result end)

      assert Enum.all?(results, &(&1 == %{country: "FR"}))
      assert_received :hit
      refute_received :hit
    end
  end
end
