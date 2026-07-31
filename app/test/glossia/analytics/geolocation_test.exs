defmodule Glossia.Analytics.GeolocationTest do
  use ExUnit.Case, async: true

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
end
