defmodule Glossia.GithubTest do
  use Glossia.DataCase, async: true
  use Mimic

  alias Glossia.Github
  alias Glossia.Projects
  alias Glossia.Repo
  alias Glossia.TestHelpers

  test "starts a translation when a commit lands on the default branch" do
    user = TestHelpers.create_user("github-push@test.com", "github-push")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "github-push-project",
        name: "GitHub push project",
        github_repo_id: 8_003,
        github_repo_full_name: "example/product",
        github_repo_default_branch: "main",
        setup_target_languages: ["de", "fr"]
      })

    Mimic.expect(Glossia.TranslationSessions, :start_continuous_session, fn received_project,
                                                                            attrs,
                                                                            opts ->
      assert received_project.id == project.id
      assert attrs.commit_sha == "new-commit-sha"
      assert attrs.commit_message == "Add the guide"
      assert attrs.source_language == "en"
      assert attrs.target_languages == ["de", "fr"]
      assert :ok = opts |> Keyword.fetch!(:validate) |> then(& &1.())
      {:ok, %{id: "session-id"}}
    end)

    Mimic.expect(Glossia.Github.Client, :get_ref, fn "example/product", "heads/main", nil ->
      {:ok, %{"object" => %{"sha" => "new-commit-sha"}}}
    end)

    assert :ok =
             Github.handle_webhook_event(%{
               "ref" => "refs/heads/main",
               "before" => "old-commit-sha",
               "after" => "new-commit-sha",
               "deleted" => false,
               "head_commit" => %{"message" => "Add the guide\n\nMore detail"},
               "repository" => %{"id" => 8_003, "default_branch" => "main"}
             })
  end

  test "ignores pushes to a non-default branch" do
    user = TestHelpers.create_user("github-feature-push@test.com", "github-feature-push")

    {:ok, _project} =
      Projects.create_project(user.account, %{
        handle: "github-feature-push-project",
        name: "GitHub feature push project",
        github_repo_id: 8_004,
        github_repo_full_name: "example/product",
        github_repo_default_branch: "main"
      })

    Mimic.reject(&Glossia.TranslationSessions.start_continuous_session/3)

    assert :ok =
             Github.handle_webhook_event(%{
               "ref" => "refs/heads/feature",
               "after" => "feature-commit-sha",
               "deleted" => false,
               "repository" => %{"id" => 8_004, "default_branch" => "main"}
             })
  end

  test "lets repository configuration select languages when project targets are empty" do
    user = TestHelpers.create_user("github-no-targets@test.com", "github-no-targets")

    {:ok, _project} =
      Projects.create_project(user.account, %{
        handle: "github-no-targets-project",
        name: "GitHub no targets project",
        github_repo_id: 8_005,
        github_repo_full_name: "example/product",
        github_repo_default_branch: "main",
        setup_target_languages: []
      })

    Mimic.expect(Glossia.Github.Client, :get_ref, fn "example/product", "heads/main", nil ->
      {:ok, %{"object" => %{"sha" => "new-commit-sha"}}}
    end)

    Mimic.expect(Glossia.TranslationSessions, :start_continuous_session, fn _project,
                                                                            attrs,
                                                                            opts ->
      assert attrs.target_languages == []
      assert :ok = opts |> Keyword.fetch!(:validate) |> then(& &1.())
      {:ok, %{id: "session-id"}}
    end)

    assert :ok =
             Github.handle_webhook_event(%{
               "ref" => "refs/heads/main",
               "after" => "new-commit-sha",
               "deleted" => false,
               "repository" => %{"id" => 8_005, "default_branch" => "main"}
             })
  end

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
