defmodule Glossia.TranslationSessions.Job do
  @moduledoc """
  The entrypoint a detached translation pod boots into.

  The pod runs the same release image as the web tier, told by environment
  which role to take. It starts a supervision tree with the database, the
  vault, PubSub and the ingestion buffers — everything the translation itself
  needs — but no HTTP endpoint, no Oban queues and no FLAME pool: it is the
  isolated compute, so it has nothing to place work onto.

  Because it joins the same BEAM cluster as the web replicas, progress reaches
  every connected LiveView through ordinary distributed PubSub. That depends on
  a stable `RELEASE_COOKIE` across the image; without one the pod boots, works,
  and silently reaches nobody.

  The pod exits when the translation ends, which is what marks the Kubernetes
  Job complete and lets its TTL clean it up.
  """

  require Logger

  alias Glossia.TranslationSessions

  @doc "Whether this process is the detached translation pod."
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
      # `Translate.run/1` records its own failures, so reaching here means
      # something escaped it. The session is failed explicitly rather than left
      # running for the reaper to find an hour later.
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
        TranslationSessions.update_session_status(session, "failed",
          error: "Translation stopped unexpectedly: #{Exception.message(exception)}"
        )
    end
  rescue
    _error -> :ok
  end

  # Stopping rather than halting: it walks the supervision tree down, which is
  # what flushes the ingestion buffers holding this session's final events.
  defp stop(:ok), do: System.stop(0)

  defp stop({:error, reason}) do
    Logger.error("Detached translation finished with an error", reason: inspect(reason))
    System.stop(1)
  end
end
