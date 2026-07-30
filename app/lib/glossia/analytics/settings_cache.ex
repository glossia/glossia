defmodule Glossia.Analytics.SettingsCache do
  @moduledoc false

  # Tiny read-optimized ETS cache for analytics project lookups. Public keys
  # rarely change, so a short TTL keeps the hot path off Postgres without
  # serving stale data for long. Entries are written from the owning GenServer
  # but read concurrently by request processes.

  use GenServer

  @table __MODULE__
  @ttl :timer.seconds(60)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get(key) do
    now = System.monotonic_time(:millisecond)

    case :ets.lookup(@table, key) do
      [{^key, entry, expires_at}]
      when expires_at > now ->
        entry

      _ ->
        :miss
    end
  end

  def put(key, entry) do
    :ets.insert(@table, {key, entry, System.monotonic_time(:millisecond) + @ttl})
    entry
  end

  @impl true
  def init(_opts) do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:set, :named_table, :public, read_concurrency: true])
    end

    {:ok, %{}}
  end
end
