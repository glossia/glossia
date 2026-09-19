defmodule Babel.Pomerium.JWKSCache do
  @moduledoc false

  import Cachex.Spec

  @cache __MODULE__
  @ttl :timer.minutes(5)

  def child_spec(opts) do
    name = Keyword.get(opts, :name, @cache)

    Supervisor.child_spec(
      {Cachex, name: name, expiration: expiration(default: @ttl)},
      id: name
    )
  end

  def fetch(resolver, cache \\ @cache) when is_function(resolver, 0) do
    case Cachex.fetch(cache, :pomerium_jwks, fn _key -> cache_result(resolver.()) end) do
      {status, {:ok, jwks}} when status in [:ok, :commit] -> {:ok, jwks}
      {status, {:error, reason}} when status in [:ok, :ignore] -> {:error, reason}
      {:error, reason} -> {:error, reason}
    end
  end

  defp cache_result({:ok, %{"keys" => keys} = jwks}) when is_list(keys),
    do: {:commit, {:ok, jwks}}

  defp cache_result({:error, _reason} = error), do: {:ignore, error}
  defp cache_result(_result), do: {:ignore, {:error, :invalid_jwks}}
end
