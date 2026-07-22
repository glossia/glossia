defmodule Glossia.Projects.SetupPullRequestSyncWorkerTest do
  use Glossia.DataCase, async: false
  use Mimic

  alias Glossia.Github.Installations
  alias Glossia.Projects
  alias Glossia.Projects.SetupPullRequestSyncWorker
  alias Glossia.Repo
  alias Glossia.TestHelpers

  test "reconciles an open setup pull request that was merged" do
    user = TestHelpers.create_user("setup-pr-sync@test.com", "setup-pr-sync")

    {:ok, installation} =
      Installations.create_installation(user.account, %{
        github_installation_id: 81,
        github_account_login: "example",
        github_account_type: "Organization",
        github_account_id: 8_100
      })

    {:ok, project} =
      Projects.create_project_from_github(user.account, installation.id, %{
        handle: "setup-pr-sync-project",
        name: "Setup pull request sync project",
        github_repo_id: 8_101,
        github_repo_full_name: "example/product",
        github_repo_default_branch: "main",
        setup_status: "completed",
        setup_pull_request_number: 24,
        setup_pull_request_url: "https://github.com/example/product/pull/24",
        setup_pull_request_state: "open"
      })

    Mimic.expect(Glossia.Github.App, :installation_token, fn 81 ->
      {:ok, "github-token"}
    end)

    Mimic.expect(Glossia.Github.Client, :get_pull_request, fn "example/product",
                                                              24,
                                                              "github-token" ->
      {:ok, %{"state" => "closed", "merged_at" => "2026-07-22T16:45:00Z"}}
    end)

    assert :ok = SetupPullRequestSyncWorker.perform(%Oban.Job{})

    updated = Repo.get!(Glossia.Accounts.Project, project.id)
    assert updated.setup_pull_request_state == "merged"
    assert updated.setup_pull_request_merged_at == ~U[2026-07-22 16:45:00.000000Z]
  end
end
