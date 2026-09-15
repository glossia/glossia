defmodule Glossia.Translations.ProviderPacingTest do
  use Glossia.DataCase, async: true
  alias Glossia.Translations
  alias Glossia.Translations.ProviderPacing

  test "short provider hints never flatten exponential backoff" do
    for attempt <- 1..8 do
      minimum = min(2_000 * Integer.pow(2, attempt - 1), 30_000)
      assert Translations.retry_delay_ms(2_000, attempt, %{retry_after_ms: 1_000}) >= minimum
    end

    assert Translations.retry_delay_ms(2_000, 1, %{retry_after_ms: 120_000}) >= 120_000
  end

  test "workers share a cooldown and recheck admission after another limit" do
    key = "pacing-#{System.unique_integer([:positive])}"
    assert :ok = ProviderPacing.admit(key)
    assert :ok = ProviderPacing.update(key, {:limited, 60_000})
    assert {:wait, delay} = ProviderPacing.admit(key)
    assert delay > 55_000
    assert :ok = ProviderPacing.update(key, {:limited, 120_000})
    assert {:wait, longer} = ProviderPacing.admit(key)
    assert longer > delay
    assert :ok = ProviderPacing.admit(key <> "-other-model")
  end

  test "concurrent workers cannot all claim the same admission slot" do
    key = "concurrent-#{System.unique_integer([:positive])}"
    :ok = ProviderPacing.admit(key)

    Repo.update_all(from(p in "translation_provider_pacing", where: p.key == ^key),
      set: [interval_ms: 30_000, next_at: 0]
    )

    results =
      1..5
      |> Enum.map(fn _ -> Task.async(fn -> ProviderPacing.admit(key) end) end)
      |> Enum.map(&Task.await/1)

    assert Enum.count(results, &(&1 == :ok)) == 1
    assert Enum.count(results, &match?({:wait, _}, &1)) == 4
  end

  test "admission spaces requests and success cannot erase a recent cooldown" do
    initial = %{next_at: 0, interval_ms: 0, limited_at: 0}
    {:ok, limited} = ProviderPacing.transition(initial, {:limited, 1_000}, 100_000)
    assert {{:wait, 1_000}, ^limited} = ProviderPacing.transition(limited, :admit, 100_000)
    {:ok, recovered} = ProviderPacing.transition(limited, :success, 100_100)
    assert recovered == limited
    {:ok, admitted} = ProviderPacing.transition(limited, :admit, 101_000)
    assert {{:wait, 1_000}, _} = ProviderPacing.transition(admitted, :admit, 101_000)
    {:ok, steady} = ProviderPacing.transition(admitted, :success, 161_000)
    assert steady.interval_ms == 900
  end
end
