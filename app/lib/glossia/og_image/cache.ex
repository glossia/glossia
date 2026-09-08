defmodule Glossia.OgImage.Cache do
  @moduledoc "A bounded cache that coalesces concurrent social-image requests."
  import Cachex.Spec

  def child_spec(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    Supervisor.child_spec(
      {Cachex,
       name: name,
       expiration: expiration(default: :timer.minutes(5)),
       hooks: [hook(module: Cachex.Limit.Scheduled, args: {100, [], []})]},
      id: name
    )
  end

  def fetch(key, resolver, cache \\ __MODULE__) do
    case Cachex.fetch(cache, key, fn _ ->
           case resolver.() do
             {:ok, bytes} -> {:commit, {:ok, bytes}}
             {:error, _} = error -> {:ignore, error}
           end
         end) do
      {status, result} when status in [:ok, :commit, :ignore] -> result
      {:error, _} = error -> error
    end
  end
end
