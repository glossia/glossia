defmodule Glossia.TranslationSessions.ContinuousTest do
  use Glossia.DataCase, async: true

  alias Glossia.Projects
  alias Glossia.Repo
  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.TranslateWorker
  alias Glossia.TranslationSessions.TranslationSession

  test "a newer commit cancels the active session and reuses its publication" do
    user = TestHelpers.create_user("continuous@test.com", "continuous")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "continuous-project",
        name: "Continuous project",
        github_repo_id: 9_001,
        github_repo_full_name: "example/continuous",
        github_repo_default_branch: "main",
        setup_target_languages: ["es"]
      })

    {:ok, active_session} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "old-source-commit",
        commit_message: "Old source",
        status: "running",
        source_language: "en",
        target_languages: ["es"],
        summary: "Translated three files before supersession.",
        error: "One file was waiting for a retry.",
        publication_branch: "glossia/translate-old-source",
        publication_commit_sha: "translated-checkpoint",
        pull_request_url: "https://github.com/example/continuous/pull/12",
        pull_request_number: 12
      })

    TranslationSessions.broadcast_session_event(active_session, %{
      type: "plan_assessed",
      seq: 1,
      total: 2,
      needs_translation: 1,
      up_to_date: 1
    })

    TranslationSessions.broadcast_session_event(active_session, %{
      type: "item_started",
      seq: 2,
      index: 0,
      output_path: "docs/es/guide.md",
      locale: "es"
    })

    TranslationSessions.broadcast_session_event(active_session, %{
      type: "item_completed",
      seq: 3,
      index: 0,
      output_path: "docs/es/guide.md",
      locale: "es"
    })

    # A second file is mid-flight when the newer commit lands: its start event
    # has been persisted but no terminating event ever arrives from the pod.
    TranslationSessions.broadcast_session_event(active_session, %{
      type: "item_started",
      seq: 4,
      index: 1,
      output_path: "docs/es/tutorial.md",
      locale: "es"
    })

    assert {:ok, replacement} =
             TranslationSessions.start_continuous_session(
               project,
               %{
                 commit_sha: "new-source-commit",
                 commit_message: "New source",
                 source_language: "en",
                 target_languages: ["es"]
               },
               enqueue: false
             )

    cancelled = Repo.get!(TranslationSession, active_session.id)
    assert cancelled.status == "cancelled"
    assert cancelled.outcome == "superseded"
    assert cancelled.translated_content_count == 1
    assert cancelled.content_hit_count == 1
    assert cancelled.completed_at
    assert cancelled.summary == "Translated three files before supersession."
    assert cancelled.error == "One file was waiting for a retry."

    assert replacement.status == "pending"
    assert replacement.commit_sha == "new-source-commit"
    assert replacement.continued_from_session_id == active_session.id
    assert replacement.publication_branch == "glossia/translate-old-source"
    assert replacement.publication_commit_sha == "translated-checkpoint"
    assert replacement.pull_request_url == "https://github.com/example/continuous/pull/12"
    assert replacement.pull_request_number == 12

    # Every in-flight file the superseded session had running is closed out so
    # a viewer folding its history no longer sees them as "Translating" forever.
    progress = TranslationSessions.session_progress(active_session.id)
    items = Glossia.TranslationSessions.Progress.items(progress)

    assert [
             %{index: 0, status: :done},
             %{index: 1, status: :cancelled, reason: "superseded"}
           ] = items
  end

  test "redelivery of the same commit does not create another session" do
    user = TestHelpers.create_user("continuous-redelivery@test.com", "continuous-redelivery")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "continuous-redelivery-project",
        name: "Continuous redelivery project",
        github_repo_id: 9_002,
        github_repo_full_name: "example/continuous-redelivery",
        github_repo_default_branch: "main"
      })

    attrs = %{
      commit_sha: "same-source-commit",
      commit_message: "Same source",
      source_language: "en",
      target_languages: ["es"]
    }

    assert {:ok, first} =
             TranslationSessions.start_continuous_session(project, attrs, enqueue: false)

    assert {:ok, second} =
             TranslationSessions.start_continuous_session(project, attrs, enqueue: false)

    assert second.id == first.id

    assert 1 ==
             TranslationSession
             |> Ecto.Query.where(project_id: ^project.id, commit_sha: "same-source-commit")
             |> Repo.aggregate(:count)
  end

  test "a failed scheduling attempt can be retried for the same commit" do
    user = TestHelpers.create_user("continuous-retry@test.com", "continuous-retry")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "continuous-retry-project",
        name: "Continuous retry project",
        github_repo_id: 9_004,
        github_repo_full_name: "example/continuous-retry",
        github_repo_default_branch: "main"
      })

    {:ok, failed} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "retry-source-commit",
        status: "failed",
        source_language: "en",
        target_languages: ["es"]
      })

    assert {:ok, retried} =
             TranslationSessions.start_continuous_session(
               project,
               %{
                 "commit_sha" => "retry-source-commit",
                 "source_language" => "en",
                 "target_languages" => ["es"],
                 "unknown_future_field" => "ignored"
               },
               enqueue: false
             )

    refute retried.id == failed.id
    assert retried.status == "pending"
    assert retried.commit_sha == "retry-source-commit"
  end

  test "redelivery repairs a pending session whose launch was not queued" do
    user = TestHelpers.create_user("continuous-orphan@test.com", "continuous-orphan")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "continuous-orphan-project",
        name: "Continuous orphan project",
        github_repo_id: 9_006,
        github_repo_full_name: "example/continuous-orphan",
        github_repo_default_branch: "main"
      })

    attrs = %{
      commit_sha: "orphaned-source-commit",
      source_language: "en",
      target_languages: ["es"]
    }

    {:ok, orphaned} =
      TranslationSessions.start_continuous_session(project, attrs, enqueue: false)

    Oban.Testing.with_testing_mode(:manual, fn ->
      assert {:ok, recovered} = TranslationSessions.start_continuous_session(project, attrs)
      assert recovered.id == orphaned.id

      session_id = to_string(orphaned.id)

      assert 1 ==
               Oban.Job
               |> Ecto.Query.where(worker: ^Oban.Worker.to_string(TranslateWorker))
               |> Ecto.Query.where(
                 [job],
                 fragment("?->>'session_id' = ?", job.args, ^session_id)
               )
               |> Repo.aggregate(:count)
    end)
  end
end
