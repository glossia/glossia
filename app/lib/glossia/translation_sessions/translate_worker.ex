defmodule Glossia.TranslationSessions.TranslateWorker do
  @moduledoc """
  Oban worker that starts a translation session.

  It launches the work rather than performing it. In a cluster that means
  creating a Job that owns its own lifetime, so this returns in a second or two
  and the hour of translating happens somewhere a deploy cannot reach. Outside
  a cluster there is nowhere to schedule onto and the translation runs here.

  `max_attempts: 1` still applies, and now means what it says: launching is
  cheap and idempotent, and a translation that has already started is not
  something this worker should start again.
  """

  use Oban.Worker,
    queue: :default,
    max_attempts: 1,
    unique: [keys: [:session_id], states: [:available, :scheduled, :executing]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"session_id" => session_id}}) do
    case Glossia.TranslationSessions.Launcher.launch(session_id) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
