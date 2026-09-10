defmodule Glossia.TranslationSessions.Launcher do
  @moduledoc """
  Placement seam for the compute a translation session runs on.

  In the open-source build a translation runs in whatever OS process asked
  for it, so `launch/1` calls `Glossia.TranslationSessions.Translate.run/1`
  directly and `cancel/1` is a no-op. A translation lives and dies with its
  host: any restart of the pod that started it — a deploy, a crash, a node
  drain — ends the translation, and a member has to resubmit the session.

  Downstream builds swap this behaviour for a scheduler that owns the
  translation's lifetime (detached Kubernetes Job, external queue, whatever
  the operator provides) through:

      config :glossia, :translation_launcher, module: MyApp.Translations.Launcher

  or by setting `GLOSSIA_TRANSLATION_LAUNCHER_MODULE` at runtime.
  """

  @callback launch(session_id :: String.t()) :: :ok | {:error, term()}
  @callback cancel(session_id :: String.t()) :: :ok | {:error, term()}

  def impl do
    :glossia
    |> Application.get_env(:translation_launcher, [])
    |> Keyword.get(:module, Glossia.TranslationSessions.Launcher.Default)
  end

  def launch(session_id), do: impl().launch(session_id)
  def cancel(session_id), do: impl().cancel(session_id)
end
