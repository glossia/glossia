defmodule Glossia.Analytics.SettingsCacheTest do
  use ExUnit.Case, async: true

  alias Glossia.Analytics.SettingsCache

  setup do
    name = :"settings_cache_#{System.unique_integer([:positive])}"
    start_supervised!({SettingsCache, name: name})
    %{cache: name}
  end

  test "returns :miss for an unknown key", %{cache: cache} do
    assert SettingsCache.get("absent.com", cache) == :miss
  end

  test "stores and reads back an entry", %{cache: cache} do
    entry = %{project_id: "p", target_languages: ["de"], enabled: true}

    assert SettingsCache.put("cache.com", entry, cache) == entry
    assert SettingsCache.get("cache.com", cache) == entry
  end

  test "delete/1 removes an entry", %{cache: cache} do
    SettingsCache.put("delete.com", %{project_id: "p"}, cache)

    assert :ok = SettingsCache.delete("delete.com", cache)
    assert SettingsCache.get("delete.com", cache) == :miss
  end

  test "expires entries once the TTL elapses", %{cache: cache} do
    SettingsCache.put("ttl.com", %{project_id: "p"}, cache)
    assert {:ok, ttl} = Cachex.ttl(cache, "ttl.com")
    assert ttl > 0 and ttl <= :timer.seconds(60)
  end
end
