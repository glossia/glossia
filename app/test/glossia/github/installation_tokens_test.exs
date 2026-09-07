defmodule Glossia.Github.InstallationTokensTest do
  use ExUnit.Case, async: true

  alias Glossia.Github.InstallationTokens

  # Each test owns its own Cachex instance, so the file stays async and nothing
  # leaks through the application-wide cache. The resolver is injected rather
  # than stubbed because `Cachex.fetch/3` runs it in a courier-spawned process
  # that does not inherit `$callers`.
  defp start_cache do
    name = :"installation_tokens_test_#{:erlang.unique_integer([:positive])}"
    start_supervised!({InstallationTokens, name: name})
    name
  end

  defp counting_resolver(result) do
    {:ok, counter} = Agent.start_link(fn -> 0 end)

    resolver = fn ->
      Agent.update(counter, &(&1 + 1))
      result
    end

    {resolver, fn -> Agent.get(counter, & &1) end}
  end

  defp expires_in(seconds) do
    DateTime.utc_now() |> DateTime.add(seconds, :second) |> DateTime.to_iso8601()
  end

  test "mints once and serves the cached token afterwards" do
    cache = start_cache()

    {resolver, calls} =
      counting_resolver({:ok, %{token: "ghs_token", expires_at: expires_in(3600)}})

    assert {:ok, "ghs_token"} = InstallationTokens.fetch(42, resolver, cache)
    assert {:ok, "ghs_token"} = InstallationTokens.fetch(42, resolver, cache)
    assert {:ok, "ghs_token"} = InstallationTokens.fetch(42, resolver, cache)

    assert calls.() == 1
  end

  test "expires the entry before GitHub expires the token" do
    cache = start_cache()
    {resolver, _calls} = counting_resolver({:ok, %{token: "t", expires_at: expires_in(3600)}})

    assert {:ok, "t"} = InstallationTokens.fetch(42, resolver, cache)

    # An hour of life, minus the five minute margin, so a token is never handed
    # out with so little left that a slow request outlives it.
    assert {:ok, ttl} = Cachex.ttl(cache, 42)
    assert_in_delta ttl, :timer.minutes(55), :timer.seconds(10)
  end

  test "keeps a token that is already inside the margin for a short while" do
    cache = start_cache()
    {resolver, _calls} = counting_resolver({:ok, %{token: "t", expires_at: expires_in(60)}})

    assert {:ok, "t"} = InstallationTokens.fetch(42, resolver, cache)

    # The margin would make this negative. Caching it briefly beats minting a
    # new token for every call in the same burst.
    assert {:ok, ttl} = Cachex.ttl(cache, 42)
    assert ttl > 0
    assert ttl <= :timer.seconds(30)
  end

  test "falls back to a conservative life when GitHub sends no usable expiry" do
    for expires_at <- [nil, "", "not-a-timestamp"] do
      cache = start_cache()
      {resolver, _calls} = counting_resolver({:ok, %{token: "t", expires_at: expires_at}})

      assert {:ok, "t"} = InstallationTokens.fetch(42, resolver, cache)

      assert {:ok, ttl} = Cachex.ttl(cache, 42)
      assert ttl <= :timer.minutes(30)
      assert ttl > :timer.minutes(29)
    end
  end

  test "does not cache a failed mint" do
    cache = start_cache()
    {:ok, attempts} = Agent.start_link(fn -> 0 end)

    resolver = fn ->
      count = Agent.get_and_update(attempts, &{&1 + 1, &1 + 1})

      if count == 1,
        do: {:error, {:api_error, 500, %{}}},
        else: {:ok, %{token: "t", expires_at: expires_in(3600)}}
    end

    # A transient GitHub error must not lock the installation out for the whole
    # TTL, so the next caller gets to try again.
    assert {:error, {:api_error, 500, %{}}} = InstallationTokens.fetch(42, resolver, cache)
    assert {:ok, "t"} = InstallationTokens.fetch(42, resolver, cache)
    assert Agent.get(attempts, & &1) == 2
  end

  test "invalidate forces the next caller to mint again" do
    cache = start_cache()

    {resolver, calls} =
      counting_resolver({:ok, %{token: "t", expires_at: expires_in(3600)}})

    assert {:ok, "t"} = InstallationTokens.fetch(42, resolver, cache)
    assert calls.() == 1

    assert :ok = InstallationTokens.invalidate(42, cache)

    assert {:ok, "t"} = InstallationTokens.fetch(42, resolver, cache)
    assert calls.() == 2
  end

  test "keys tokens per installation" do
    cache = start_cache()

    assert {:ok, "one"} =
             InstallationTokens.fetch(
               1,
               fn -> {:ok, %{token: "one", expires_at: expires_in(3600)}} end,
               cache
             )

    assert {:ok, "two"} =
             InstallationTokens.fetch(
               2,
               fn -> {:ok, %{token: "two", expires_at: expires_in(3600)}} end,
               cache
             )

    assert {:ok, "one"} = InstallationTokens.fetch(1, fn -> flunk("should be cached") end, cache)
  end
end
