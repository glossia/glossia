defmodule Babel.Organizations.UsageCache do
  @moduledoc false

  import Cachex.Spec

  @cache __MODULE__
  @limit 500
  @ttl :timer.minutes(10)

  def child_spec(opts) do
    name = Keyword.get(opts, :name, @cache)

    Supervisor.child_spec(
      {Cachex,
       name: name,
       expiration: expiration(default: @ttl),
       hooks: [hook(module: Cachex.Limit.Scheduled, args: {@limit, [], []})]},
      id: name
    )
  end

  def fetch(organization_id, resolver, cache \\ @cache)
      when is_binary(organization_id) and is_function(resolver, 0) do
    case Cachex.fetch(cache, {:organization_usage, organization_id}, fn _key ->
           cache_result(resolver.())
         end) do
      {status, {:ok, usage}} when status in [:ok, :commit] -> {:ok, usage}
      {status, result} when status in [:ok, :ignore] -> result
      {:error, reason} -> {:error, reason}
    end
  end

  defp cache_result({:ok, usage} = result) when is_map(usage), do: {:commit, result}
  defp cache_result(result), do: {:ignore, result}
end
