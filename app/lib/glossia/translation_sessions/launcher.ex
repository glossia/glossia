defmodule Glossia.TranslationSessions.Launcher do
  @moduledoc """
  Starts a translation session in the calling process.

  In the open-source build a translation runs in whatever OS process asked
  for it, so `launch/1` calls `Glossia.TranslationSessions.Translate.run/1`
  directly. That means a translation lives and dies with its host: any
  restart of the pod that started it — a deploy, a crash, a node drain —
  ends the translation, and a member has to resubmit the session.

  A downstream build that wants translations to survive its host swaps
  this module (through the ordinary Elixir module boundary) for one that
  hands the work to a scheduler owning the lifetime itself. `cancel/1`
  stays as the cooperative signal such a scheduler can hook into.
  """

  alias Glossia.TranslationSessions

  @doc """
  Runs the session in the calling process.

  Returns `:ok` once the translation finishes, whatever the outcome. The
  return value is meant for logging and testability; session status is
  written by `Translate.run/1` itself.
  """
  def launch(session_id) do
    TranslationSessions.Translate.run(session_id)
    :ok
  end

  @doc "Cooperative cancellation hook. In the OSS build there is nothing to signal."
  def cancel(_session_id), do: :ok
end
