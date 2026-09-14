defmodule Glossia.TranslationSessions.ProviderRecovery do
  @moduledoc """
  Schedules bounded continuations after provider throttling exhausts local retries.

  Each continuation has its own session and launcher identity, inherits the
  publication branch, and reuses durable segment checkpoints. A newer active
  session wins. Six delayed continuations bound cost during a provider outage.
  """
  import Ecto.Query
  alias Glossia.Repo
  alias Glossia.Accounts.Project
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.{TranslationSession, TranslateWorker}
  alias Glossia.Translations.Failure

  def rate_limited?({:translation_items_failed, failures}) do
    Enum.any?(failures, fn failure ->
      Failure.normalize(Map.get(failure, :reason)).kind == "provider-rate-limit"
    end)
  end

  def rate_limited?(_), do: false

  def schedule(%TranslationSession{} = session) do
    Repo.transaction(fn ->
      Repo.one!(from p in Project, where: p.id == ^session.project_id, lock: "FOR UPDATE")
      current = Repo.get!(TranslationSession, session.id)

      newer =
        Repo.exists?(
          from s in TranslationSession,
            where: s.project_id == ^current.project_id and s.id != ^current.id,
            where:
              s.inserted_at >= ^current.inserted_at and
                s.status in ["pending", "running", "completed"]
        )

      existing =
        Repo.exists?(
          from s in TranslationSession, where: s.continued_from_session_id == ^current.id
        )

      if current.status == "failed" and current.provider_retry_count < 6 and not newer and
           not existing do
        fields =
          Map.take(current, [
            :account_id,
            :project_id,
            :commit_sha,
            :commit_message,
            :source_language,
            :target_languages,
            :publication_branch,
            :publication_commit_sha,
            :pull_request_url,
            :pull_request_number
          ])

        continuation =
          struct(
            TranslationSession,
            Map.merge(fields, %{
              continued_from_session_id: current.id,
              provider_retry_count: current.provider_retry_count + 1
            })
          )
          |> Repo.insert!()

        delay = min(60 * Integer.pow(2, current.provider_retry_count), 300)

        %{session_id: continuation.id}
        |> TranslateWorker.new(schedule_in: delay)
        |> Oban.insert!()

        continuation
      else
        nil
      end
    end)
    |> case do
      {:ok, %TranslationSession{} = continuation} ->
        TranslationSessions.broadcast_session_status(continuation, "pending")
        {:ok, continuation}

      result ->
        result
    end
  end
end
