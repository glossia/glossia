defmodule Glossia.TranslationSessions.EngineRecoveryTest do
  use Glossia.DataCase, async: true
  use Oban.Testing, repo: Glossia.Repo
  use Mimic

  alias Glossia.Accounts.Project
  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions

  alias Glossia.TranslationSessions.{
    EngineRecovery,
    EngineRecoveryWorker,
    EngineRelease,
    ProgressEvent,
    TranslationSession,
    TranslateWorker
  }

  alias Glossia.Translations.Failure

  @old_image "ghcr.io/glossia/glossia@sha256:#{String.duplicate("a", 64)}"
  @new_image "ghcr.io/glossia/glossia@sha256:#{String.duplicate("b", 64)}"
  @third_image "ghcr.io/glossia/glossia@sha256:#{String.duplicate("c", 64)}"

  defp release(image \\ @new_image),
    do: %{image: image, deployed_at: DateTime.add(DateTime.utc_now(), -60, :second)}

  setup do
    user = TestHelpers.create_user("engine-recovery@test.com", "engine-recovery")

    project =
      Repo.insert!(%Project{account_id: user.account.id, handle: "recovery", name: "Recovery"})

    now = DateTime.utc_now()

    session =
      Repo.insert!(%TranslationSession{
        account_id: user.account.id,
        project_id: project.id,
        status: "failed",
        failure_kind: "translation_items_failed",
        engine_image: @old_image,
        commit_sha: "source",
        publication_branch: "glossia/translate/source",
        publication_commit_sha: "checkpoint",
        target_languages: ["es"],
        provider_retry_count: 2,
        inserted_at: DateTime.add(now, -180, :second),
        started_at: DateTime.add(now, -120, :second),
        completed_at: now
      })

    failure(
      session,
      1,
      Failure.from({:validation_failed, "translated Markdown changed the document structure"})
    )

    %{session: session}
  end

  defp failure(session, index, reason) do
    TranslationSessions.broadcast_session_event(session, %{
      type: "item_failed",
      seq: index,
      index: index,
      output_path: "docs/guide.md",
      reason: reason
    })
  end

  defp change_session(session, changes),
    do: session |> Ecto.Changeset.change(changes) |> Repo.update!()

  test "continues an overlapping failure once, preserving publication and provider retry bounds",
       %{session: session} do
    Oban.Testing.with_testing_mode(:manual, fn ->
      assert [candidate] = EngineRecovery.candidates(release())
      assert candidate.id == session.id
      assert {:ok, continuation} = EngineRecovery.schedule(session, release())
      assert continuation.continued_from_session_id == session.id
      assert continuation.engine_retry_count == 1
      assert continuation.provider_retry_count == 2
      assert continuation.previous_engine_images == [@old_image]
      assert continuation.publication_branch == session.publication_branch
      assert continuation.publication_commit_sha == "checkpoint"
      assert continuation.commit_sha == "source"
      assert is_nil(continuation.engine_image)
      assert_enqueued(worker: TranslateWorker, args: %{session_id: continuation.id})
      assert {:ok, nil} = EngineRecovery.schedule(session, release())
      assert [] = EngineRecovery.candidates(release())
    end)
  end

  test "a healthy release triggers recovery through the scheduled worker", %{session: session} do
    stub(EngineRelease, :ready_release, fn -> {:ok, release()} end)

    Oban.Testing.with_testing_mode(:manual, fn ->
      assert :ok = EngineRecoveryWorker.perform(%Oban.Job{})

      continuation =
        Repo.one!(from s in TranslationSession, where: s.continued_from_session_id == ^session.id)

      assert continuation.engine_retry_count == 1
      assert :ok = EngineRecoveryWorker.perform(%Oban.Job{})
      assert length(all_enqueued(worker: TranslateWorker)) == 1
    end)
  end

  test "a rollout in progress cannot schedule recovery" do
    stub(EngineRelease, :ready_release, fn -> :not_ready end)
    assert :ok = EngineRecoveryWorker.perform(%Oban.Job{})
    refute_enqueued(worker: TranslateWorker)
  end

  test "records the executing image separately from the source commit", %{session: session} do
    session = change_session(session, status: "pending", engine_image: nil)
    assert {:ok, started} = TranslationSessions.start_session(session, @new_image)
    assert started.engine_image == @new_image
    assert started.commit_sha == "source"
    assert is_nil(started.failure_kind)
    assert {:ok, restarted} = TranslationSessions.start_session(started, @old_image)
    assert restarted.engine_image == @new_image
  end

  test "a different image alone does not retry ordinary failures before or after a rollout", %{
    session: session
  } do
    now = DateTime.utc_now()

    for deployed_at <- [DateTime.add(now, -240, :second), DateTime.add(now, 60, :second)] do
      unrelated_release = %{image: @new_image, deployed_at: deployed_at}
      assert [] = EngineRecovery.candidates(unrelated_release)
      assert {:ok, nil} = EngineRecovery.schedule(session, unrelated_release)
    end
  end

  test "a job queued before rollout can boot after rollout and still recover", %{session: session} do
    delayed = change_session(session, started_at: DateTime.add(DateTime.utc_now(), -30, :second))
    assert [_] = EngineRecovery.candidates(release())

    Oban.Testing.with_testing_mode(:manual, fn ->
      assert {:ok, %TranslationSession{}} = EngineRecovery.schedule(delayed, release())
    end)
  end

  test "old failures, crashes, unknown versions and bounded lineages are excluded", %{
    session: session
  } do
    assert {:ok, nil} = EngineRecovery.schedule(session, release(@old_image))
    assert {:ok, nil} = EngineRecovery.schedule(session, release("image:main"))
    now = DateTime.utc_now()

    for changes <- [
          %{engine_image: nil},
          %{engine_image: "image:old"},
          %{engine_retry_count: 3},
          %{failure_kind: "translation_failed"},
          %{failure_kind: nil},
          %{completed_at: DateTime.add(now, -7 * 3600, :second)},
          %{previous_engine_images: [@new_image]}
        ] do
      changed = change_session(session, changes)
      assert {:ok, nil} = EngineRecovery.schedule(changed, release())
      assert [] = EngineRecovery.candidates(release())

      change_session(
        changed,
        Map.take(session, [
          :engine_image,
          :engine_retry_count,
          :failure_kind,
          :completed_at,
          :previous_engine_images
        ])
      )
    end
  end

  test "does not revive cancelled, completed, running, or pending sessions", %{session: session} do
    for status <- ["cancelled", "completed", "running", "pending"] do
      change_session(session, status: status)
      assert {:ok, nil} = EngineRecovery.schedule(session, release())
    end
  end

  test "any newer session wins, including a user's cancelled replacement", %{session: session} do
    Repo.insert!(%TranslationSession{
      account_id: session.account_id,
      project_id: session.project_id,
      status: "cancelled"
    })

    assert {:ok, nil} = EngineRecovery.schedule(session, release())
    assert [] = EngineRecovery.candidates(release())
  end

  test "provider, publication and command failures are not retried by a deployment", %{
    session: session
  } do
    for kind <- [
          "provider-credit",
          "provider-credentials",
          "provider-rate-limit",
          "source-unreadable",
          "validation-command",
          "publication-failed"
        ] do
      Repo.delete_all(from e in ProgressEvent, where: e.session_id == ^session.id)
      failure(session, 1, %{kind: kind})
      assert {:ok, nil} = EngineRecovery.schedule(session, release())
      assert [] = EngineRecovery.candidates(release())
    end
  end

  test "mixed engine and provider failures cannot consume release retries", %{session: session} do
    failure(session, 2, Failure.from({:llm_failed, "insufficient credit"}))
    assert {:ok, nil} = EngineRecovery.schedule(session, release())
    assert [] = EngineRecovery.candidates(release())
  end

  test "cancelled items exclude a partially crashed run", %{session: session} do
    TranslationSessions.broadcast_session_event(session, %{
      type: "item_cancelled",
      seq: 2,
      index: 2,
      output_path: "docs/other.md"
    })

    assert {:ok, nil} = EngineRecovery.schedule(session, release())
    assert [] = EngineRecovery.candidates(release())
  end

  test "unfinished items are excluded even if terminal-event cleanup failed", %{session: session} do
    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      seq: 2,
      index: 2,
      output_path: "docs/unfinished.md"
    })

    assert [] = EngineRecovery.candidates(release())
    assert {:ok, nil} = EngineRecovery.schedule(session, release())

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_completed",
      seq: 3,
      index: 2,
      output_path: "docs/unfinished.md"
    })

    assert [_] = EngineRecovery.candidates(release())
  end

  test "only the latest attempt's failures are considered in SQL and in scheduling", %{
    session: session
  } do
    TranslationSessions.broadcast_session_event(session, %{type: "run_started", seq: 2})
    assert [] = EngineRecovery.candidates(release())
    assert {:ok, nil} = EngineRecovery.schedule(session, release())

    failure(
      session,
      3,
      Failure.from({:validation_failed, "every tag must appear exactly once: <g1/>"})
    )

    assert [_] = EngineRecovery.candidates(release())

    Oban.Testing.with_testing_mode(:manual, fn ->
      assert {:ok, %TranslationSession{}} = EngineRecovery.schedule(session, release())
    end)
  end

  test "earlier attempt provider failures do not disqualify a clean latest attempt", %{
    session: session
  } do
    failure(session, 2, Failure.from({:llm_failed, "insufficient credit"}))
    TranslationSessions.broadcast_session_event(session, %{type: "run_started", seq: 3})

    failure(
      session,
      4,
      Failure.from({:validation_failed, "translated Markdown changed the document structure"})
    )

    assert [_] = EngineRecovery.candidates(release())
  end

  test "an image is never repeated in the recovery lineage, including rollbacks", %{
    session: session
  } do
    Oban.Testing.with_testing_mode(:manual, fn ->
      {:ok, continuation} = EngineRecovery.schedule(session, release())

      continuation =
        change_session(continuation,
          status: "failed",
          failure_kind: "translation_items_failed",
          engine_image: @new_image,
          inserted_at: session.inserted_at,
          started_at: session.started_at,
          completed_at: session.completed_at
        )

      failure(
        continuation,
        1,
        Failure.from({:validation_failed, "translated Markdown changed the document structure"})
      )

      assert {:ok, nil} = EngineRecovery.schedule(continuation, release())
      assert {:ok, nil} = EngineRecovery.schedule(continuation, release(@old_image))
      assert [] = EngineRecovery.candidates(release(@old_image))
      assert [candidate] = EngineRecovery.candidates(release(@third_image))
      assert candidate.id == continuation.id
    end)
  end
end
