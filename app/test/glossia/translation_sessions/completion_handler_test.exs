defmodule Glossia.TranslationSessions.CompletionHandlerTest do
  use Glossia.DataCase, async: false

  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.CompletionHandler
  alias Glossia.TranslationSessions.TranslationSession

  defmodule Recorder do
    @behaviour Glossia.TranslationSessions.CompletionHandler

    @impl true
    def on_completed(session) do
      send(:completion_handler_test, {:on_completed, session.id})
      :ok
    end
  end

  setup do
    Process.register(self(), :completion_handler_test)

    original = Application.get_env(:glossia, :translation_session_completion_handler, [])

    Application.put_env(:glossia, :translation_session_completion_handler, module: Recorder)

    on_exit(fn ->
      Application.put_env(:glossia, :translation_session_completion_handler, original)
    end)

    :ok
  end

  test "fires when a session transitions to completed" do
    user = TestHelpers.create_user("owner@example.com", "owner-#{System.unique_integer([:positive])}")

    {:ok, project} =
      Glossia.Projects.create_project(user.account, %{
        name: "Test Project",
        handle: "proj-#{System.unique_integer([:positive])}",
        repository_url: "https://github.com/owner/repo"
      })

    {:ok, %TranslationSession{} = session} =
      Glossia.Repo.insert(%TranslationSession{
        account_id: user.account.id,
        project_id: project.id,
        status: "running",
        commit_sha: "abc123",
        source_language: "en"
      })

    {:ok, _} = TranslationSessions.update_session_status(session, "completed")

    assert_receive {:on_completed, id}, 500
    assert id == session.id
  end

  test "does not fire when transitioning to a non-completed status" do
    user = TestHelpers.create_user("owner2@example.com", "owner-#{System.unique_integer([:positive])}")

    {:ok, project} =
      Glossia.Projects.create_project(user.account, %{
        name: "Test Project",
        handle: "proj-#{System.unique_integer([:positive])}",
        repository_url: "https://github.com/owner/repo"
      })

    {:ok, %TranslationSession{} = session} =
      Glossia.Repo.insert(%TranslationSession{
        account_id: user.account.id,
        project_id: project.id,
        status: "pending",
        source_language: "en"
      })

    {:ok, _} = TranslationSessions.update_session_status(session, "running")

    refute_receive {:on_completed, _}, 100
  end

  test "impl/0 returns the configured module" do
    assert CompletionHandler.impl() == Recorder
  end
end
