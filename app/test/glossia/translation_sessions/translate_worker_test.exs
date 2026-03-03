defmodule Glossia.TranslationSessions.TranslateWorkerTest do
  use Glossia.DataCase, async: true

  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.{TranslateWorker, TranslationSession}
  alias Glossia.Projects
  alias GlossiaWeb.ApiTestHelpers

  setup do
    user = ApiTestHelpers.create_user("worker@test.com", "worker-user")
    account = user.account

    {:ok, project} =
      Projects.create_project(account, %{
        handle: "worker-proj-#{System.unique_integer([:positive])}",
        name: "Worker Project",
        setup_status: "completed",
        setup_target_languages: ["es", "fr"]
      })

    %{account: account, project: project}
  end

  describe "perform/1" do
    test "creates a translation session for a commit", %{project: project} do
      assert :ok =
               TranslateWorker.perform(%Oban.Job{
                 args: %{
                   "project_id" => project.id,
                   "commit_sha" => "abc123",
                   "commit_message" => "feat: add new feature"
                 }
               })

      sessions =
        Repo.all(
          from(s in TranslationSession,
            where: s.project_id == ^project.id and s.commit_sha == "abc123"
          )
        )

      assert length(sessions) == 1
      [session] = sessions
      assert session.status == "pending"
      assert session.source_language == "en"
      assert session.target_languages == ["es", "fr"]
      assert session.commit_message == "feat: add new feature"
    end

    test "cancels active sessions before creating a new one", %{
      account: account,
      project: project
    } do
      {:ok, existing} =
        TranslationSessions.create_session(account, project, %{
          "commit_sha" => "old-commit",
          "status" => "pending",
          "source_language" => "en",
          "target_languages" => ["es"]
        })

      assert :ok =
               TranslateWorker.perform(%Oban.Job{
                 args: %{
                   "project_id" => project.id,
                   "commit_sha" => "new-commit",
                   "commit_message" => "fix: bug fix"
                 }
               })

      cancelled = Repo.get!(TranslationSession, existing.id)
      assert cancelled.status == "failed"
      assert cancelled.error =~ "superseded"
    end

    test "skips session creation when no target languages configured", %{account: account} do
      {:ok, empty_project} =
        Projects.create_project(account, %{
          handle: "empty-proj-#{System.unique_integer([:positive])}",
          name: "Empty Project",
          setup_status: "completed",
          setup_target_languages: []
        })

      assert :ok =
               TranslateWorker.perform(%Oban.Job{
                 args: %{
                   "project_id" => empty_project.id,
                   "commit_sha" => "skip123",
                   "commit_message" => "should be skipped"
                 }
               })

      sessions =
        Repo.all(
          from(s in TranslationSession,
            where: s.project_id == ^empty_project.id
          )
        )

      assert sessions == []
    end
  end
end
