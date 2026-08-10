defmodule Glossia.Analytics.SettingsCacheTest do
  # Not async: shares the process-wide named ETS table. Keys are unique per test.
  use ExUnit.Case, async: false

  alias Glossia.Analytics.SettingsCache

  test "returns :miss for an unknown key" do
    assert SettingsCache.get("absent-#{System.unique_integer([:positive])}.com") == :miss
  end

  test "stores and reads back an entry" do
    key = "cache-#{System.unique_integer([:positive])}.com"
    entry = %{project_id: "p", target_languages: ["de"], enabled: true}

    assert SettingsCache.put(key, entry) == entry
    assert SettingsCache.get(key) == entry
  end

  test "delete/1 removes an entry" do
    key = "delete-#{System.unique_integer([:positive])}.com"
    SettingsCache.put(key, %{project_id: "p"})

    assert :ok = SettingsCache.delete(key)
    assert SettingsCache.get(key) == :miss
  end
end
