defmodule Glossia.GithubTest do
  use Glossia.DataCase, async: true
  use Mimic

  alias Glossia.Github
  alias Glossia.Projects
  alias Glossia.Translations.Translation
  alias GlossiaWeb.ApiTestHelpers

  import Ecto.Query

  setup do
    stub(Glossia.Sandbox.Docker, :create, fn _params -> {:ok, "glossia-sandbox-test"} end)
    stub(Glossia.Sandbox.Docker, :delete, fn _id -> :ok end)

    stub(Glossia.Sandbox.Docker, :execute, fn _id, _cmd, _opts ->
      {:ok, %{"exitCode" => 0, "result" => ""}}
    end)

    stub(Glossia.Sandbox.Docker, :upload_file, fn _id, _path, _content -> :ok end)

    stub(Glossia.Sandbox.Docker, :download_file, fn _id, _path ->
      {:ok, ~s({"status":"completed"})}
    end)

    :ok
  end

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

      translations =
        Repo.all(
          from(t in Translation,
            where: t.project_id == ^project.id and t.commit_sha == "deadbeef123"
          )
        )

      assert length(translations) == 1
      [translation] = translations
      assert translation.commit_message == "feat: add new page"
      assert translation.target_languages == ["es", "de"]
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

      translations =
        Repo.all(from(t in Translation, where: t.project_id == ^project.id))

      assert translations == []
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

      translations =
        Repo.all(from(t in Translation, where: t.project_id == ^project.id))

      assert translations == []
    end

    test "prefers default branch from webhook payload over persisted value", %{project: project} do
      event = %{
        "ref" => "refs/heads/develop",
        "repository" => %{"id" => project.github_repo_id, "default_branch" => "develop"},
        "head_commit" => %{
          "id" => "payload-branch-123",
          "message" => "push to develop"
        }
      }

      assert :ok = Github.handle_webhook_event("push", event)

      translations =
        Repo.all(
          from(t in Translation,
            where: t.project_id == ^project.id and t.commit_sha == "payload-branch-123"
          )
        )

      assert length(translations) == 1
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

      translations =
        Repo.all(from(t in Translation, where: t.project_id == ^project_no_branch.id))

      assert length(translations) == 1
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
