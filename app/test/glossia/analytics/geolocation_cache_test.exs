defmodule Glossia.Analytics.GeolocationCacheTest do
  use ExUnit.Case, async: true

  import Cachex.Spec

  alias Glossia.Analytics.Geolocation.Ipapi.Cache

  setup do
    name = :"geolocation_cache_#{:erlang.unique_integer([:positive])}"
    start_supervised!({Cache, name: name})
    %{cache: name}
  end

  test "successful lookups have a 24-hour expiry", %{cache: cache} do
    assert Cache.fetch("8.8.8.8", fn _ -> {:commit, "US"} end, cache) == "US"
    assert {:ok, ttl} = Cachex.ttl(cache, "8.8.8.8")
    assert ttl > 0 and ttl <= :timer.hours(24)
  end

  test "configures scheduled size limiting and expiry reclamation", %{cache: name} do
    %{start: {Cachex, :start_link, [opts]}} = Cache.child_spec(name: name)
    assert opts[:expiration] == expiration(default: :timer.hours(24))
    assert hook(module: Cachex.Limit.Scheduled, args: {100_000, [], []}) in opts[:hooks]
  end

  test "failed lookups are not stored", %{cache: cache} do
    resolver = fn _ -> {:ignore, nil} end
    assert Cache.fetch("8.8.8.8", resolver, cache) == nil
    assert Cachex.exists?(cache, "8.8.8.8") == {:ok, false}
    assert Cache.fetch("8.8.8.8", fn _ -> {:commit, "US"} end, cache) == "US"
  end

  test "concurrent misses share a resolver and later reads use the cache", %{cache: cache} do
    test_pid = self()

    resolver = fn _ ->
      send(test_pid, :resolved)
      Process.sleep(50)
      {:commit, "US"}
    end

    results =
      1..10
      |> Task.async_stream(fn _ -> Cache.fetch("8.8.8.8", resolver, cache) end,
        max_concurrency: 10
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert results == List.duplicate("US", 10)
    assert Cache.fetch("8.8.8.8", resolver, cache) == "US"
    assert_received :resolved
    refute_received :resolved
  end
end
