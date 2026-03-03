defmodule Glossia.GithubTest do
  use Glossia.DataCase, async: true

  alias Glossia.Github
  alias Glossia.Projects
  alias Glossia.TranslationSessions.TranslationSession
  alias GlossiaWeb.ApiTestHelpers

  import Ecto.Query

  describe "handle_webhook_event/2 push events" do
    setup do
      user = ApiTestHelpers.create_user("gh-push@test.com", "gh-push")
      account = user.account

      {:ok, project} =
        Projects.create_project(account, %{
          handle: "gh-push-proj-#{System.unique_integer([:positive])}",
          name: "GH Push Project",
          github_repo_id: 12345,
          github_repo_full_name: "acme/push-project",
          github_repo_default_branch: "main",
          setup_status: "completed",
          setup_target_languages: ["es", "de"]
        })

      %{account: account, project: project}
    end

    test "enqueues a translation job for a push to the default branch", %{project: project} do
      event = %{
        "ref" => "refs/heads/main",
        "repository" => %{"id" => project.github_repo_id},
        "head_commit" => %{
          "id" => "deadbeef123",
          "message" => "feat: add new page\n\nDetailed description"
        }
      }

      assert :ok = Github.handle_webhook_event("push", event)

      sessions =
        Repo.all(
          from(s in TranslationSession,
            where: s.project_id == ^project.id and s.commit_sha == "deadbeef123"
          )
        )

      assert length(sessions) == 1
      [session] = sessions
      assert session.commit_message == "feat: add new page"
      assert session.target_languages == ["es", "de"]
    end

    test "ignores pushes to non-default branches", %{project: project} do
      event = %{
        "ref" => "refs/heads/feature-branch",
        "repository" => %{"id" => project.github_repo_id},
        "head_commit" => %{
          "id" => "abc123",
          "message" => "wip"
        }
      }

      assert :ok = Github.handle_webhook_event("push", event)

      sessions =
        Repo.all(from(s in TranslationSession, where: s.project_id == ^project.id))

      assert sessions == []
    end

    test "ignores pushes for unknown repositories" do
      event = %{
        "ref" => "refs/heads/main",
        "repository" => %{"id" => 0},
        "head_commit" => %{
          "id" => "unknown123",
          "message" => "test"
        }
      }

      assert :ok = Github.handle_webhook_event("push", event)
    end

    test "ignores pushes without head_commit (branch deletions)", %{project: project} do
      event = %{
        "ref" => "refs/heads/main",
        "repository" => %{"id" => project.github_repo_id},
        "head_commit" => nil
      }

      assert :ok = Github.handle_webhook_event("push", event)

      sessions =
        Repo.all(from(s in TranslationSession, where: s.project_id == ^project.id))

      assert sessions == []
    end

    test "defaults to 'main' when project has no default branch set", %{account: account} do
      {:ok, project_no_branch} =
        Projects.create_project(account, %{
          handle: "no-branch-#{System.unique_integer([:positive])}",
          name: "No Branch Project",
          github_repo_id: 99999,
          github_repo_full_name: "acme/no-branch",
          setup_status: "completed",
          setup_target_languages: ["fr"]
        })

      event = %{
        "ref" => "refs/heads/main",
        "repository" => %{"id" => 99999},
        "head_commit" => %{
          "id" => "default123",
          "message" => "test default branch"
        }
      }

      assert :ok = Github.handle_webhook_event("push", event)

      sessions =
        Repo.all(from(s in TranslationSession, where: s.project_id == ^project_no_branch.id))

      assert length(sessions) == 1
    end
  end

  describe "handle_webhook_event/2 installation events" do
    test "returns :ok for unhandled actions" do
      event = %{
        "action" => "new_permissions_accepted",
        "installation" => %{"id" => 123, "account" => %{"login" => "acme"}}
      }

      assert :ok = Github.handle_webhook_event("installation", event)
    end
  end

  describe "handle_webhook_event/2 unknown events" do
    test "returns :ok for unknown event types" do
      assert :ok = Github.handle_webhook_event("unknown", %{"some" => "data"})
    end
  end
end
