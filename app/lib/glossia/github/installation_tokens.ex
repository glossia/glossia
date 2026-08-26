defmodule Glossia.Github.InstallationTokens do
  @moduledoc false

  # Cachex-backed cache for GitHub App installation tokens, keyed by
  # installation id.
  #
  # GitHub expires an installation token one hour after it is minted. A caller
  # that holds one for the length of a long translation run therefore ends up
  # presenting a dead credential and gets a 401 "Bad credentials" on its first
  # write, which is what used to end those runs with nothing published. Caching
  # here lets every call site ask for a token at the moment it needs one
  # without minting a fresh token per request.
  #
  # Entries expire on GitHub's own `expires_at`, minus a margin so a token is
  # never handed out with so little life left that a slow request outlives it.
  # A response without a usable `expires_at` falls back to a conservative TTL
  # rather than assuming the full hour.
  #
  # The key space is bounded by the number of installations we have records
  # for, but a size limit keeps a surprise there from growing the table without
  # end; the janitor reclaims expired rows in between.

  import Cachex.Spec

  @cache __MODULE__
  @expiry_margin_ms :timer.minutes(5)
  # The most a token can honestly be worth: GitHub's hour, less the margin. It
  # also bounds a nonsense far-future `expires_at`.
  @max_ttl :timer.minutes(55)
  # Used when GitHub sends no usable expiry, so we assume less than the hour
  # rather than more.
  @fallback_ttl :timer.minutes(30)
  @min_ttl :timer.seconds(30)
  @max_size 10_000

  # `:name` lets a test start its own scoped instance rather than share the
  # application-wide one.
  def child_spec(opts) do
    name = Keyword.get(opts, :name, @cache)

    Supervisor.child_spec(
      {Cachex,
       name: name, hooks: [hook(module: Cachex.Limit.Scheduled, args: {@max_size, [], []})]},
      id: name
    )
  end

  @doc """
  Returns a cached token for `installation_id`, invoking `resolver` on a miss.

  `resolver` returns `{:ok, %{token: token, expires_at: expires_at}}` or an
  error. Cachex routes concurrent misses for the same installation through a
  single resolver call, so a burst of publications cannot fan out into a burst
  of token requests. A failed mint is never cached, so a transient GitHub error
  does not lock the installation out for the rest of the TTL.
  """
  def fetch(installation_id, resolver, cache \\ @cache) do
    case Cachex.fetch(cache, installation_id, fn _key -> commit(resolver.()) end) do
      {status, {:ok, token}} when status in [:ok, :commit, :ignore] -> {:ok, token}
      {status, {:error, reason}} when status in [:ok, :commit, :ignore] -> {:error, reason}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Drops the cached token for `installation_id`.

  Used when GitHub rejects a token we believed was live, so the next caller
  mints a new one instead of replaying the rejected credential.
  """
  def invalidate(installation_id, cache \\ @cache) do
    Cachex.del(cache, installation_id)
    :ok
  end

  defp commit({:ok, %{token: token, expires_at: expires_at}}) when is_binary(token),
    do: {:commit, {:ok, token}, expire: ttl(expires_at)}

  defp commit({:ok, token}) when is_binary(token),
    do: {:commit, {:ok, token}, expire: @fallback_ttl}

  # `:ignore` keeps the failure out of the cache, so the next caller retries.
  defp commit({:error, _reason} = error), do: {:ignore, error}
  defp commit(other), do: {:ignore, {:error, {:invalid_installation_token, other}}}

  defp ttl(%DateTime{} = expires_at) do
    expires_at
    |> DateTime.diff(DateTime.utc_now(), :millisecond)
    |> Kernel.-(@expiry_margin_ms)
    |> clamp()
  end

  defp ttl(expires_at) when is_binary(expires_at) do
    case DateTime.from_iso8601(expires_at) do
      {:ok, parsed, _offset} -> ttl(parsed)
      {:error, _reason} -> @fallback_ttl
    end
  end

  defp ttl(_expires_at), do: @fallback_ttl

  # A token already inside the margin is still worth caching briefly: the
  # alternative is minting a new one for every call in the same burst.
  defp clamp(ttl), do: ttl |> max(@min_ttl) |> min(@max_ttl)
end
