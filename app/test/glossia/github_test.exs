defmodule Glossia.GithubTest do
  use Glossia.DataCase, async: true

  alias Glossia.Github
  alias Glossia.Projects
  alias Glossia.Repo
  alias Glossia.TestHelpers

  test "marks a setup pull request as merged from a GitHub webhook" do
    user = TestHelpers.create_user("github-merge@test.com", "github-merge")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "github-merge-project",
        name: "GitHub merge project",
        github_repo_id: 8_001,
        setup_status: "completed",
        setup_pull_request_number: 92,
        setup_pull_request_url: "https://github.com/glossia/glossia/pull/92",
        setup_pull_request_state: "open"
      })

    Projects.subscribe_setup_events(project)

    assert :ok =
             Github.handle_webhook_event(%{
               "action" => "closed",
               "installation" => %{"id" => 123},
               "repository" => %{"id" => 8_001},
               "pull_request" => %{
                 "number" => 92,
                 "merged" => true,
                 "merged_at" => "2026-07-22T16:30:00Z"
               }
             })

    updated = Repo.get!(Glossia.Accounts.Project, project.id)
    assert updated.setup_pull_request_state == "merged"
    assert updated.setup_pull_request_merged_at == ~U[2026-07-22 16:30:00.000000Z]
    assert_receive {:setup_pull_request, ^updated}
  end

  test "marks an unmerged setup pull request as closed and allows it to reopen" do
    user = TestHelpers.create_user("github-close@test.com", "github-close")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "github-close-project",
        name: "GitHub close project",
        github_repo_id: 8_002,
        setup_status: "completed",
        setup_pull_request_number: 12,
        setup_pull_request_url: "https://github.com/example/product/pull/12",
        setup_pull_request_state: "open"
      })

    base_event = %{
      "installation" => %{"id" => 123},
      "repository" => %{"id" => 8_002},
      "pull_request" => %{"number" => 12, "merged" => false, "merged_at" => nil}
    }

    assert :ok = Github.handle_webhook_event(Map.put(base_event, "action", "closed"))

    assert Repo.get!(Glossia.Accounts.Project, project.id).setup_pull_request_state == "closed"

    assert :ok = Github.handle_webhook_event(Map.put(base_event, "action", "reopened"))

    reopened = Repo.get!(Glossia.Accounts.Project, project.id)
    assert reopened.setup_pull_request_state == "open"
    assert is_nil(reopened.setup_pull_request_merged_at)
  end
end
