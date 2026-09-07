defmodule Glossia.TranslationSessions.SessionRecoveryWorker do
  @moduledoc "Ends abandoned translation sessions so they stop showing as running."

  use Oban.Worker,
    queue: :default,
    max_attempts: 1,
    unique: [period: 240, states: [:available, :scheduled, :executing, :retryable]]

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Glossia.TranslationSessions.expire_stale_sessions()
    :ok
  end
end
