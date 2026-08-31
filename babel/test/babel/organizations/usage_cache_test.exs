defmodule Babel.Organizations.UsageCacheTest do
  use ExUnit.Case, async: true

  alias Babel.Organizations.UsageCache

  test "caches successful Glossia usage lookups" do
    cache = :"organization_usage_cache_#{:erlang.unique_integer([:positive])}"
    organization_id = "1d82348e-0175-4abf-aeb8-3f2e8304c7a1"
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    start_supervised!({UsageCache, name: cache})

    resolver = fn ->
      Agent.update(calls, &(&1 + 1))
      {:ok, %{projects: 2}}
    end

    assert {:ok, %{projects: 2}} = UsageCache.fetch(organization_id, resolver, cache)
    assert {:ok, %{projects: 2}} = UsageCache.fetch(organization_id, resolver, cache)
    assert Agent.get(calls, & &1) == 1
  end

  test "does not cache an unavailable usage lookup" do
    cache = :"organization_usage_cache_#{:erlang.unique_integer([:positive])}"
    organization_id = "1d82348e-0175-4abf-aeb8-3f2e8304c7a1"
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    start_supervised!({UsageCache, name: cache})

    resolver = fn ->
      Agent.update(calls, &(&1 + 1))
      {:error, :unavailable}
    end

    assert {:error, :unavailable} = UsageCache.fetch(organization_id, resolver, cache)
    assert {:error, :unavailable} = UsageCache.fetch(organization_id, resolver, cache)
    assert Agent.get(calls, & &1) == 2
  end
end
