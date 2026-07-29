defmodule Glossia.TranslationSessions.TranslateWorker do
  @moduledoc """
  Oban worker that runs a translation session.
  """

  use Oban.Worker,
    queue: :default,
    max_attempts: 3,
    unique: [keys: [:session_id], states: [:available, :scheduled, :executing, :retryable]]

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"session_id" => session_id},
        attempt: attempt,
        max_attempts: max_attempts
      }) do
    case Glossia.TranslationSessions.Translate.run(session_id,
           terminal_failure?: attempt >= max_attempts
         ) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
