defmodule Glossia.Analytics.GeolocationTest do
  use ExUnit.Case, async: false

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

    setup :verify_on_exit!

    test "treats empty IPs as unknown" do
      assert Ipapi.lookup("") == %{country: nil}
    end

    test "skips the network for private and loopback addresses" do
      for ip <- ["127.0.0.1", "10.0.0.5", "192.168.1.1", "172.16.0.1", "169.254.1.1", "::1"] do
        assert Ipapi.lookup(ip) == %{country: nil}, "expected #{ip} to short-circuit"
      end
    end

    test "returns nil on a non-200 response" do
      ip = "203.0.113.10"

      expect(Req, :get, fn _url, _opts ->
        {:ok, %Req.Response{status: 429, body: %{"error" => "rate limit"}}}
      end)

      assert Ipapi.lookup(ip) == %{country: nil}
    end

    test "returns the country code from a well-formed payload and memoizes it" do
      ip = "203.0.113.20"

      test_pid = self()

      expect(Req, :get, fn _url, _opts ->
        send(test_pid, :hit)
        {:ok, %Req.Response{status: 200, body: %{"location" => %{"country_code" => "US"}}}}
      end)

      assert Ipapi.lookup(ip) == %{country: "US"}
      assert_received :hit
      # Second call must be served from the ETS cache, no extra HTTP request.
      assert Ipapi.lookup(ip) == %{country: "US"}
      refute_received :hit
    end

    test "ignores responses that do not carry a 2-letter country code" do
      ip = "203.0.113.30"

      expect(Req, :get, fn _url, _opts ->
        {:ok, %Req.Response{status: 200, body: %{"location" => %{"country_code" => nil}}}}
      end)

      assert Ipapi.lookup(ip) == %{country: nil}
    end
  end
end
