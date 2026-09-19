defmodule Babel.Organizations.DirectoryCache do
  @moduledoc false

  import Cachex.Spec

  @cache __MODULE__
  @limit 1
  @ttl :timer.minutes(5)

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

  def fetch(resolver, cache \\ @cache) when is_function(resolver, 0) do
    case Cachex.fetch(cache, :glossia_organization_directory, fn _key ->
           cache_result(resolver.())
         end) do
      {status, {:ok, organizations}} when status in [:ok, :commit] -> {:ok, organizations}
      {status, result} when status in [:ok, :ignore] -> result
      {:error, reason} -> {:error, reason}
    end
  end

  defp cache_result({:ok, organizations} = result) when is_list(organizations),
    do: {:commit, result}

  defp cache_result(result), do: {:ignore, result}
end
