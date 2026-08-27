defmodule Glossia.TranslationSessions.ProgressCache do
  @moduledoc false

  # A reconnecting LiveView cannot replay the high-volume progress stream, so
  # keep its compact, folded form briefly. Session identifiers originate in the
  # database, but the size limit still bounds the cache if many sessions run at
  # once.

  import Cachex.Spec

  alias Glossia.TranslationSessions.Progress

  @cache __MODULE__
  @ttl :timer.hours(2)
  @max_size 100

  def child_spec(opts) do
    name = Keyword.get(opts, :name, @cache)

    Supervisor.child_spec(
      {Cachex,
       name: name,
       expiration: expiration(default: @ttl),
       hooks: [hook(module: Cachex.Limit.Scheduled, args: {@max_size, [], []})]},
      id: name
    )
  end

  def get(session_id, cache \\ @cache) do
    case Cachex.get(cache, session_id) do
      {:ok, nil} -> Progress.new()
      {:ok, progress} -> progress
      _error -> Progress.new()
    end
  end

  def apply_event(session_id, event, cache \\ @cache) do
    progress =
      session_id
      |> get(cache)
      |> Progress.apply_event(event)

    Cachex.put(cache, session_id, progress)
    progress
  end

  def clear(session_id, cache \\ @cache) do
    Cachex.del(cache, session_id)
    :ok
  end
end
