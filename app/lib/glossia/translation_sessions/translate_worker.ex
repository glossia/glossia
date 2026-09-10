defmodule Glossia.TranslationSessions.TranslateWorker do
  @moduledoc """
  Oban worker that starts a translation session.

  In the open-source build the translation runs synchronously in this worker
  process — `Launcher.launch/1` is a straight call into
  `TranslationSessions.Translate.run/1`. `max_attempts: 1` still applies:
  a translation that already started is not something this worker should
  start again, and the launcher writes its own status so a partial run is
  visible without being retried.
  """

  use Oban.Worker,
    queue: :default,
    max_attempts: 1,
    unique: [keys: [:session_id], states: [:available, :scheduled, :executing]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"session_id" => session_id}}) do
    Glossia.TranslationSessions.Launcher.launch(session_id)
    :ok
  end
end
