defmodule Glossia.TranslationSessions.PublicationBatch do
  @moduledoc """
  Groups a run's validated files into a few commits instead of one per file.

  Every push to the translation branch triggers the repository's pull request
  checks. Publishing each file as it is validated meant a 150-file run pushed
  150 times and exhausted the repository's CI runners. A batch collects the
  changes of completed files and publishes them as one commit once it holds
  `:max_files` files or `:max_interval_ms` has passed since the last push.
  These are batching thresholds, not permission to bypass the project-wide
  push budget. A publisher returning `{:wait, ms}` keeps collecting files
  until the shared budget admits a push. `flush/1` waits outside the batch
  process for that budget rather than bypassing it at the end of a run.

  A failed push keeps the changes pending; the next push, or the final flush,
  retries them.
  """

  use Agent

  require Logger

  alias Glossia.Translations.Failure

  @default_max_files 25
  @default_max_interval_ms :timer.minutes(15)
  # Publishing builds blobs, a tree, and a commit through the GitHub API. A
  # large batch can take a while, and the caller is a worker waiting to report
  # its file as done.
  @call_timeout_ms :timer.minutes(10)

  @doc """
  Starts a batch that publishes through `publish`, a function receiving the
  list of `%{path, status, content}` changes to commit.

  Options: `:max_files` and `:max_interval_ms`. Defaults come from
  `config :glossia, #{inspect(__MODULE__)}`.
  """
  def start_link(publish, opts \\ []) when is_function(publish, 1) do
    config = Application.get_env(:glossia, __MODULE__, [])

    state = %{
      publish: publish,
      max_files: option(opts, config, :max_files, @default_max_files),
      max_interval_ms: option(opts, config, :max_interval_ms, @default_max_interval_ms),
      pending: %{},
      pending_files: 0,
      last_published_at: System.monotonic_time(:millisecond),
      next_attempt_at: nil
    }

    callers = [self() | Process.get(:"$callers", [])]

    # Like a `Task`, the batch records the processes it works for, so database
    # ownership and test stubs follow the run into its publishing calls.
    Agent.start_link(fn ->
      Process.put(:"$callers", callers)
      state
    end)
  end

  @doc """
  Adds one completed file's changes, publishing the batch when it is due.

  Always returns `:ok`: the file is validated and written, and a push that
  fails here is retried with the next one.
  """
  def add(batch, changes) when is_list(changes) do
    Agent.get_and_update(
      batch,
      fn state ->
        state =
          %{
            state
            | pending: Enum.reduce(changes, state.pending, &Map.put(&2, &1.path, &1)),
              pending_files: state.pending_files + 1
          }

        if due?(state), do: {:ok, publish(state)}, else: {:ok, state}
      end,
      @call_timeout_ms
    )
  end

  @doc "Publishes pending changes, waiting for the shared push budget if needed."
  def flush(batch) do
    result =
      Agent.get_and_update(
        batch,
        fn state ->
          state = publish(state)

          result =
            cond do
              state.pending == %{} -> :ok
              state.next_attempt_at -> {:wait, state.next_attempt_at}
              true -> {:error, state.last_error}
            end

          {result, state}
        end,
        @call_timeout_ms
      )

    case result do
      {:wait, next_attempt_at} ->
        # Recheck regularly so cancellation and heartbeats still work during a
        # long cooldown, without holding an Agent call or database transaction.
        remaining_ms = max(next_attempt_at - System.monotonic_time(:millisecond), 1)
        Process.sleep(min(remaining_ms, 30_000))
        flush(batch)

      result ->
        result
    end
  end

  @doc "Stops the batch process."
  def stop(batch), do: Agent.stop(batch)

  defp due?(state) do
    now = System.monotonic_time(:millisecond)

    (is_nil(state.next_attempt_at) or now >= state.next_attempt_at) and
      (state.pending_files >= state.max_files or
         now - state.last_published_at >= state.max_interval_ms)
  end

  defp publish(%{pending: pending} = state) when pending == %{}, do: state

  defp publish(state) do
    changes = state.pending |> Map.values() |> Enum.sort_by(& &1.path)

    case safely_publish(state.publish, changes) do
      :ok ->
        %{
          state
          | pending: %{},
            pending_files: 0,
            last_published_at: System.monotonic_time(:millisecond),
            next_attempt_at: nil
        }
        |> Map.delete(:last_error)

      {:wait, ms} ->
        %{state | next_attempt_at: System.monotonic_time(:millisecond) + ms}

      {:error, reason} ->
        Logger.warning("Could not publish a batch of translations, keeping it for the next push",
          publication_code:
            Failure.from({:translation_publication_failed, reason}).publication_code,
          files: state.pending_files
        )

        state |> Map.put(:last_error, reason) |> Map.put(:next_attempt_at, nil)
    end
  end

  defp safely_publish(publish, changes) do
    publish |> apply([changes]) |> normalize()
  rescue
    _error -> {:error, :publication_callback_failed}
  end

  defp normalize({:wait, ms}) when is_integer(ms) and ms > 0, do: {:wait, ms}
  defp normalize(:ok), do: :ok
  defp normalize({:ok, _publication}), do: :ok
  defp normalize({:error, _reason} = error), do: error
  defp normalize(other), do: {:error, {:invalid_publication_result, other}}

  defp option(opts, config, key, default),
    do: Keyword.get(opts, key) || Keyword.get(config, key) || default
end
