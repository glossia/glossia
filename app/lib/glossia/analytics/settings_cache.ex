defmodule Glossia.Analytics.SettingsCache do
  @moduledoc false

  # Cachex-backed cache for analytics project lookups, keyed by site domain.
  # Domains rarely change, so a short TTL keeps the hot path off Postgres
  # without serving stale data for long. Cachex owns the table and runs a
  # janitor that reclaims expired rows, so entries for domains that are never
  # looked up again do not accumulate.

  import Cachex.Spec

  @cache __MODULE__
  @ttl :timer.seconds(60)

  # `:name` lets a test start its own scoped instance and stay `async: true`
  # instead of sharing the application-wide one.
  def child_spec(opts) do
    name = Keyword.get(opts, :name, @cache)

    Supervisor.child_spec({Cachex, name: name, expiration: expiration(default: @ttl)}, id: name)
  end

  @doc """
  Returns the cached entry for `key`, or `:miss` when absent or expired.
  """
  def get(key, cache \\ @cache) do
    case Cachex.get(cache, key) do
      {:ok, nil} -> :miss
      {:ok, entry} -> entry
      _error -> :miss
    end
  end

  def put(key, entry, cache \\ @cache) do
    Cachex.put(cache, key, entry)
    entry
  end

  def delete(key, cache \\ @cache) do
    Cachex.del(cache, key)
    :ok
  end
end
