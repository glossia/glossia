defmodule Glossia.Analytics.Config do
  @moduledoc false

  # Centralized access to the `:glossia, Glossia.Analytics` configuration so the
  # ingestion modules share a single source of truth.

  @app :glossia
  @key Glossia.Analytics

  def config, do: Application.get_env(@app, @key, [])

  def fetch!(key), do: config() |> Keyword.fetch!(key)
  def get(key, default \\ nil), do: config() |> Keyword.get(key, default)

  def enabled?, do: get(:enabled, true)

  # Falls back to Noop rather than a network adapter: an install that has not
  # configured geolocation should not start shipping visitor IPs to a third
  # party as a side effect of the default. Production opts in explicitly in
  # `runtime.exs`.
  def geolocation_adapter,
    do: get(:geolocation, []) |> Keyword.get(:adapter, Glossia.Analytics.Geolocation.Noop)
end
