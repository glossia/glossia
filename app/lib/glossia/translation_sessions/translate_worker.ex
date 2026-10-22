defmodule Glossia.TranslationSessions.TranslateWorker do
  @moduledoc """
  Oban worker that starts a translation session.

  In the local dev/test path the translation runs synchronously in this worker
  process — `Launcher.launch/1` is a straight call into
  `TranslationSessions.Translate.run/1`. `max_attempts: 1` still applies:
  a translation that already started is not something this worker should
  start again, and the launcher writes its own status so a partial run is
  visible without being retried. A release-recovery session may snooze before
  launch while its Deployment is rolling out; no translation has started then.
  """

  use Oban.Worker,
    queue: :default,
    max_attempts: 1,
    unique: [keys: [:session_id], states: [:available, :scheduled, :executing]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"session_id" => session_id}}) do
    case Glossia.TranslationSessions.Launcher.launch(session_id) do
      {:snooze, _seconds} = result -> result
      _result -> :ok
    end
  end
end
