defmodule Glossia.TranslationSessions.EngineRecovery do
  @moduledoc """
  Continues recent engine-related failures that overlapped a newer rollout.

  A different digest alone is not a reason to retry. The failed run must have
  been queued before the current release became healthy and finished after it.
  Only the latest attempt's known validation failures qualify, with at most
  three release continuations and no repeated image in the lineage.
  """

  import Ecto.Query

  alias Glossia.Accounts.Project
  alias Glossia.Repo
  alias Glossia.TranslationSessions

  alias Glossia.TranslationSessions.{
    EngineRelease,
    Progress,
    ProgressEvent,
    TranslationSession,
    TranslateWorker
  }

  alias Glossia.Translations.Failure

  @max_continuations 3
  @max_age_seconds 6 * 60 * 60

  def candidates(%{image: image, deployed_at: deployed_at}, limit \\ 50) do
    cutoff = DateTime.add(DateTime.utc_now(), -@max_age_seconds, :second)

    latest_start =
      from e in ProgressEvent,
        where: e.session_id == parent_as(:session).id,
        where: fragment("?->>'type' = 'run_started'", e.payload),
        select: coalesce(max(e.seq), 0)

    latest_events =
      from e in ProgressEvent,
        where: e.session_id == parent_as(:session).id,
        where: e.seq > subquery(latest_start)

    failures =
      from e in latest_events,
        where: fragment("?->>'type' = 'item_failed'", e.payload)

    terminals =
      from e in ProgressEvent,
        where: e.session_id == parent_as(:unfinished).session_id,
        where: e.seq > parent_as(:unfinished).seq,
        where: fragment("?->>'index' = ?->>'index'", e.payload, parent_as(:unfinished).payload),
        where: fragment("?->>'type' IN ('item_completed', 'item_failed')", e.payload)

    unfinished =
      from e in latest_events,
        as: :unfinished,
        where: fragment("?->>'type' = 'item_started'", e.payload),
        where: not exists(subquery(terminals))

    unrecoverable =
      dynamic(
        [e],
        not fragment(
          "COALESCE(?->'reason'->>'kind' IN ('validation-structure', 'validation-preserved-content') OR (?->'reason'->>'kind' = 'validation' AND ?->'reason'->>'validation_code' LIKE 'markdown-unit-%'), false)",
          e.payload,
          e.payload,
          e.payload
        )
      )

    from(s in TranslationSession,
      as: :session,
      where: s.status == "failed" and s.failure_kind == "translation_items_failed",
      where: not is_nil(s.engine_image) and s.engine_image != ^image,
      where: fragment("? ~ '@sha256:[a-f0-9]{64}$'", s.engine_image),
      where: ^image not in s.previous_engine_images,
      where: s.engine_retry_count < @max_continuations,
      where: s.completed_at > ^cutoff,
      where: s.inserted_at <= ^deployed_at and s.completed_at >= ^deployed_at,
      where: exists(subquery(failures)),
      where: not exists(subquery(unfinished)),
      where: not exists(subquery(from e in failures, where: ^unrecoverable)),
      where:
        not exists(
          subquery(
            from e in latest_events,
              where: fragment("?->>'type' = 'item_cancelled'", e.payload)
          )
        ),
      where:
        not exists(
          from newer in TranslationSession,
            where: newer.project_id == parent_as(:session).project_id,
            where:
              newer.inserted_at > parent_as(:session).inserted_at or
                (newer.inserted_at == parent_as(:session).inserted_at and
                   newer.id > parent_as(:session).id),
            select: 1
        ),
      order_by: [asc: s.completed_at, asc: s.id],
      limit: ^limit
    )
    |> Repo.all()
  end

  def schedule(%TranslationSession{} = session, %{} = release) do
    Repo.transaction(fn ->
      Repo.one!(from p in Project, where: p.id == ^session.project_id, lock: "FOR UPDATE")
      current = Repo.get!(TranslationSession, session.id)

      newer? =
        Repo.exists?(
          from s in TranslationSession,
            where: s.project_id == ^current.project_id,
            where:
              s.inserted_at > ^current.inserted_at or
                (s.inserted_at == ^current.inserted_at and s.id > ^current.id)
        )

      if eligible?(current, release) and not newer? and recoverable?(current) do
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
            :pull_request_number,
            :provider_retry_count
          ])

        continuation =
          struct(
            TranslationSession,
            Map.merge(fields, %{
              continued_from_session_id: current.id,
              engine_retry_count: current.engine_retry_count + 1,
              previous_engine_images: [current.engine_image | current.previous_engine_images]
            })
          )
          |> Repo.insert!()

        %{session_id: continuation.id}
        |> TranslateWorker.new()
        |> Oban.insert!()

        continuation
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

  defp eligible?(session, %{image: image, deployed_at: deployed_at}) do
    cutoff = DateTime.add(DateTime.utc_now(), -@max_age_seconds, :second)

    session.status == "failed" and session.failure_kind == "translation_items_failed" and
      EngineRelease.pinned?(session.engine_image) and EngineRelease.pinned?(image) and
      session.engine_image != image and image not in session.previous_engine_images and
      session.engine_retry_count < @max_continuations and
      not is_nil(session.started_at) and not is_nil(session.completed_at) and
      DateTime.compare(session.completed_at, cutoff) == :gt and
      DateTime.compare(session.inserted_at, deployed_at) != :gt and
      DateTime.compare(session.completed_at, deployed_at) != :lt
  end

  defp recoverable?(session) do
    items = session.id |> TranslationSessions.session_progress() |> Progress.items()
    failures = Enum.filter(items, &(&1.status == :failed))

    failures != [] and Enum.all?(items, &(&1.status in [:done, :failed])) and
      Enum.all?(failures, &recoverable_failure?(&1.reason))
  end

  defp recoverable_failure?(reason) do
    case Failure.normalize(reason) do
      %{kind: kind} when kind in ["validation-structure", "validation-preserved-content"] -> true
      %{kind: "validation", validation_code: "markdown-unit-" <> _} -> true
      _ -> false
    end
  end
end
