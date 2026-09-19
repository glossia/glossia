defmodule Glossia.TranslationSessions.CompletionHandler do
  @moduledoc """
  Seam invoked when a translation session transitions to `completed`.

  The open-source build does nothing — the commit produced by the session is
  the final artifact, and the session is considered done. A downstream build
  swaps this behaviour for one that runs validation in an isolated sandbox
  and, if the checks pass, promotes the commit to `main`. Configure through:

      config :glossia, :translation_session_completion_handler, module: MyApp.CompletionHandler

  or set `GLOSSIA_TRANSLATION_SESSION_COMPLETION_HANDLER_MODULE` at runtime.

  The callback runs inline after the session record is updated, so an
  implementation that does heavy work should hand off to a background job
  rather than block the caller.
  """

  alias Glossia.TranslationSessions.TranslationSession

  @callback on_completed(TranslationSession.t()) :: :ok | {:error, term()}

  def impl do
    :glossia
    |> Application.get_env(:translation_session_completion_handler, [])
    |> Keyword.get(:module, Glossia.TranslationSessions.CompletionHandler.Default)
  end

  def on_completed(%TranslationSession{} = session), do: impl().on_completed(session)
end
