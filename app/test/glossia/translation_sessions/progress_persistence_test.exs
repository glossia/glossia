defmodule Glossia.TranslationSessions.ProgressPersistenceTest do
  @moduledoc """
  The panel has to survive the run that produced it.

  A translation happens in a pod that is not the one serving the LiveView, and
  that pod is gone by the time most people open the page. These cover the path
  that makes the panel readable anyway: the events are written down, and folding
  them back gives the same state the live stream would have built.
  """

  use Glossia.DataCase, async: true

  alias Glossia.Projects
  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions

  defp session_fixture(email, handle) do
    user = TestHelpers.create_user(email, handle)

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "#{handle}-project",
        name: "Project"
      })

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "abc1234567890",
        source_language: "en",
        target_languages: ["es"]
      })

    session
  end

  test "a viewer arriving after the run rebuilds the panel from what was written" do
    session = session_fixture("progress@test.com", "progress")

    for event <- [
          %{type: "plan", total: 2, seq: 1},
          %{type: "item_started", index: 0, output_path: "es/a.md", locale: "es", seq: 2},
          %{type: "item_completed", index: 0, file_ref: "ref-a", seq: 3},
          %{type: "item_started", index: 1, output_path: "es/b.md", locale: "es", seq: 4}
        ] do
      TranslationSessions.broadcast_session_event(session, event)
    end

    progress = TranslationSessions.session_progress(session.id)

    assert progress.total == 2
    assert %{done: 1, running: 1} = TranslationSessions.Progress.summary(progress)

    [first, second] = TranslationSessions.Progress.items(progress)
    assert first.output_path == "es/a.md"
    assert first.status == :done
    assert first.file_ref == "ref-a"
    assert second.output_path == "es/b.md"
    assert second.status == :running
  end

  test "the streamed text is not written down, so it costs one row per file, not thousands" do
    session = session_fixture("chunks@test.com", "chunks")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 0,
      output_path: "es/a.md",
      seq: 1
    })

    for n <- 2..50 do
      TranslationSessions.broadcast_session_event(session, %{
        type: "item_event",
        index: 0,
        event: %{type: "text", text: "chunk"},
        seq: n
      })
    end

    assert TranslationSessions.max_progress_seq(session.id) == 1

    # The file is still there and still running; only its in-flight text is not.
    progress = TranslationSessions.session_progress(session.id)
    assert [%{status: :running, text: ""}] = TranslationSessions.Progress.items(progress)
  end

  test "a redelivered event does not fold twice" do
    session = session_fixture("dupe@test.com", "dupe")

    event = %{type: "item_skipped", seq: 1}
    TranslationSessions.broadcast_session_event(session, event)
    TranslationSessions.broadcast_session_event(session, event)

    assert TranslationSessions.session_progress(session.id).skipped == 1
  end

  test "a second attempt continues the numbering rather than restarting it" do
    session = session_fixture("resume@test.com", "resume")

    TranslationSessions.broadcast_session_event(session, %{type: "plan", total: 1, seq: 1})
    assert TranslationSessions.max_progress_seq(session.id) == 1

    TranslationSessions.broadcast_session_event(session, %{type: "plan", total: 3, seq: 2})
    assert TranslationSessions.max_progress_seq(session.id) == 2
  end

  test "a session with no run yet has an empty panel rather than an error" do
    session = session_fixture("empty@test.com", "empty")

    assert TranslationSessions.session_progress(session.id) ==
             TranslationSessions.Progress.new()

    assert TranslationSessions.max_progress_seq(session.id) == 0
  end
end
