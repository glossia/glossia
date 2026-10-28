defmodule GlossiaEnterprise.TranslationSessions.Job do
  @moduledoc """
  Entrypoint for a detached translation Job pod.

  Booted by `GlossiaEnterprise.TranslationSessions.Launcher.launch/1` with
  `GLOSSIA_TRANSLATION_JOB=1`. The Enterprise runtime reads the environment
  flag and replaces the parent's supervision tree with the
  translation-job tree, which ends with this module as its last child. The
  child_spec starts a `Task` that runs the translation and stops the VM
  when it's done, which marks the Kubernetes Job complete and lets its
  TTL clean up.

  The pod joins the same BEAM cluster as the web replicas, so progress
  reaches every connected LiveView through ordinary distributed PubSub.
  That depends on a stable `RELEASE_COOKIE` across the image; without one
  the pod boots, works, and silently reaches nobody.
  """

  require Logger

  alias Glossia.TranslationSessions

  @doc "Whether this process is a detached translation-job pod."
  def current? do
    System.get_env("GLOSSIA_TRANSLATION_JOB") in ["1", "true"]
  end

  @doc "The session this pod was started to translate."
  def session_id do
    case System.get_env("GLOSSIA_TRANSLATION_SESSION_ID") do
      id when is_binary(id) and id != "" -> {:ok, id}
      _ -> {:error, :translation_session_id_missing}
    end
  end

  def child_spec(_opts) do
    %{id: __MODULE__, start: {Task, :start_link, [&run/0]}, restart: :temporary}
  end

  @doc false
  def run do
    case session_id() do
      {:ok, id} -> stop(translate(id))
      {:error, reason} -> stop({:error, reason})
    end
  end

  defp translate(id) do
    Logger.info("Starting detached translation", translation_session_id: id)
    TranslationSessions.Translate.run(id)
  rescue
    exception ->
      Logger.error("Detached translation crashed",
        translation_session_id: id,
        error: Exception.format(:error, exception, __STACKTRACE__)
      )

      fail(id, exception)
      {:error, exception}
  end

  defp fail(id, exception) do
    case TranslationSessions.get_session(id) do
      nil ->
        :ok

      session ->
        TranslationSessions.finish_session(session, "failed",
          error: "Translation stopped unexpectedly: #{Exception.message(exception)}"
        )
    end
  rescue
    _error -> :ok
  end

  # Stopping rather than halting: it walks the supervision tree down, which
  # is what flushes the ingestion buffers holding this session's final events.
  defp stop(:ok), do: System.stop(0)

  defp stop({:error, reason}) do
    Logger.error("Detached translation finished with an error", reason: inspect(reason))
    System.stop(1)
  end
end
