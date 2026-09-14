defmodule Glossia.Translations.ProviderPacing do
  @moduledoc """
  Coordinates request admission across workers and application replicas.

  A credential/model shares a database row. Throttling increases the spacing
  between requests and extends the shared cooldown; successes slowly reduce
  spacing after a quiet minute. Workers sleep outside transactions and recheck
  admission after waking, so a newer cooldown also applies to waiting workers.
  """
  alias Glossia.Repo
  alias Glossia.Translations.Checkpoints

  def key(credential), do: Checkpoints.key({credential.model, credential.auth})

  def await(key, opts \\ []) do
    case relay(opts, :admit, [key]) do
      :ok ->
        :ok

      {:wait, ms} ->
        if on_wait = Keyword.get(opts, :on_wait), do: on_wait.(ms)
        Process.sleep(min(ms, 30_000))
        await(key, opts)
    end
  end

  def limited(key, delay, opts \\ []), do: relay(opts, :update, [key, {:limited, delay}])
  def succeeded(key, opts \\ []), do: relay(opts, :update, [key, :success])

  def admit(key), do: transaction(key, :admit)
  def update(key, event), do: transaction(key, event)

  def transition(state, :admit, now) do
    if state.next_at > now do
      {{:wait, state.next_at - now}, state}
    else
      {:ok, %{state | next_at: now + state.interval_ms}}
    end
  end

  def transition(state, {:limited, delay}, now) do
    interval = min(max(state.interval_ms * 2, 1_000), 30_000)

    {:ok,
     %{
       state
       | interval_ms: interval,
         limited_at: now,
         next_at: max(state.next_at, now + max(delay, interval))
     }}
  end

  def transition(state, :success, now) do
    interval =
      if now - state.limited_at >= 60_000,
        do: max(state.interval_ms - 100, 0),
        else: state.interval_ms

    {:ok, %{state | interval_ms: interval}}
  end

  defp transaction(key, event) do
    {:ok, result} =
      Repo.transaction(fn ->
        Repo.query!(
          "INSERT INTO translation_provider_pacing (key, expires_at) VALUES ($1, clock_timestamp() + interval '1 day') ON CONFLICT DO NOTHING",
          [key]
        )

        %{rows: [[next_at, interval, limited_at, now]]} =
          Repo.query!(
            "SELECT next_at, interval_ms, limited_at, (extract(epoch FROM clock_timestamp()) * 1000)::bigint FROM translation_provider_pacing WHERE key = $1 FOR UPDATE",
            [key]
          )

        {result, state} =
          transition(
            %{next_at: next_at, interval_ms: interval, limited_at: limited_at},
            event,
            now
          )

        Repo.query!(
          "UPDATE translation_provider_pacing SET next_at = $2, interval_ms = $3, limited_at = $4, expires_at = clock_timestamp() + interval '1 day' WHERE key = $1",
          [key, state.next_at, state.interval_ms, state.limited_at]
        )

        result
      end)

    result
  end

  defp relay(opts, function, args) do
    target = Keyword.get(opts, :credential_node, node())

    if target == node(),
      do: apply(__MODULE__, function, args),
      else: :erpc.call(target, __MODULE__, function, args, 15_000)
  end
end
