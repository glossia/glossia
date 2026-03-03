defmodule Glossia.TranslationSessionsTest do
  use Glossia.DataCase, async: true

  alias Glossia.TranslationSessions
  alias Glossia.Projects
  alias GlossiaWeb.ApiTestHelpers

  setup do
    user = ApiTestHelpers.create_user("sessions@test.com", "sessions-user")
    account = user.account

    {:ok, project} =
      Projects.create_project(account, %{
        handle: "sess-proj-#{System.unique_integer([:positive])}",
        name: "Sessions Project"
      })

    %{account: account, project: project}
  end

  describe "cancel_active_sessions/1" do
    test "cancels pending sessions", %{account: account, project: project} do
      {:ok, session} =
        TranslationSessions.create_session(account, project, %{
          "commit_sha" => "abc123",
          "status" => "pending",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      assert {:ok, 1} = TranslationSessions.cancel_active_sessions(project)

      updated = Repo.get!(TranslationSessions.TranslationSession, session.id)
      assert updated.status == "failed"
      assert updated.error == "Cancelled: superseded by newer commit"
      assert updated.completed_at != nil
    end

    test "cancels running sessions", %{account: account, project: project} do
      {:ok, session} =
        TranslationSessions.create_session(account, project, %{
          "commit_sha" => "def456",
          "status" => "running",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      assert {:ok, 1} = TranslationSessions.cancel_active_sessions(project)

      updated = Repo.get!(TranslationSessions.TranslationSession, session.id)
      assert updated.status == "failed"
    end

    test "does not cancel already completed or failed sessions", %{
      account: account,
      project: project
    } do
      {:ok, _completed} =
        TranslationSessions.create_session(account, project, %{
          "commit_sha" => "comp1",
          "status" => "completed",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      {:ok, _failed} =
        TranslationSessions.create_session(account, project, %{
          "commit_sha" => "fail1",
          "status" => "failed",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      assert {:ok, 0} = TranslationSessions.cancel_active_sessions(project)
    end

    test "cancels multiple active sessions", %{account: account, project: project} do
      for sha <- ["aaa", "bbb", "ccc"] do
        TranslationSessions.create_session(account, project, %{
          "commit_sha" => sha,
          "status" => "pending",
          "source_language" => "en",
          "target_languages" => ["es"]
        })
      end

      assert {:ok, 3} = TranslationSessions.cancel_active_sessions(project)
    end

    test "does not affect sessions from other projects", %{account: account, project: project} do
      {:ok, other_project} =
        Projects.create_project(account, %{
          handle: "other-proj-#{System.unique_integer([:positive])}",
          name: "Other Project"
        })

      {:ok, _own_session} =
        TranslationSessions.create_session(account, project, %{
          "commit_sha" => "own1",
          "status" => "pending",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      {:ok, other_session} =
        TranslationSessions.create_session(account, other_project, %{
          "commit_sha" => "other1",
          "status" => "pending",
          "source_language" => "en",
          "target_languages" => ["fr"]
        })

      assert {:ok, 1} = TranslationSessions.cancel_active_sessions(project)

      other_updated = Repo.get!(TranslationSessions.TranslationSession, other_session.id)
      assert other_updated.status == "pending"
    end
  end

  describe "get_session/1" do
    test "returns nil for invalid UUID", %{} do
      assert TranslationSessions.get_session("not-a-uuid") == nil
    end

    test "returns nil for non-existent UUID", %{} do
      assert TranslationSessions.get_session(Ecto.UUID.generate()) == nil
    end

    test "returns session with preloaded associations", %{account: account, project: project} do
      {:ok, session} =
        TranslationSessions.create_session(account, project, %{
          "commit_sha" => "xyz",
          "status" => "pending",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      result = TranslationSessions.get_session(session.id)
      assert result.id == session.id
      assert result.project.id == project.id
      assert result.account.id == account.id
    end
  end
end
