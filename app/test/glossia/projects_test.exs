defmodule Glossia.ProjectsTest do
  use Glossia.DataCase, async: true

  alias Glossia.Github.Installations
  alias Glossia.Projects
  alias Glossia.Repo
  alias Glossia.TestHelpers

  defp valid_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        handle: "project-#{System.unique_integer([:positive])}",
        name: "Test Project"
      },
      overrides
    )
  end

  test "create_project/3 creates a project and emits an event" do
    user = TestHelpers.create_user("project-create@test.com", "project-create")

    assert {:ok, project} =
             TestHelpers.expect_event(
               "project.created",
               fn ->
                 Projects.create_project(user.account, valid_attrs(),
                   actor: user,
                   via: :dashboard
                 )
               end,
               %{
                 :account_id => user.account.id,
                 :user_id => user.id,
                 {:opt, :via} => :dashboard,
                 {:opt, :resource_type} => "project"
               }
             )

    assert project.account_id == user.account.id
    assert project.name == "Test Project"
  end

  test "create_project/2 without actor still creates the project" do
    user = TestHelpers.create_user("project-no-event@test.com", "project-no-event")

    assert {:ok, project} = Projects.create_project(user.account, valid_attrs())
    assert project.account_id == user.account.id
  end

  test "create_project_from_github/4 stores installation and emits imported summary" do
    user = TestHelpers.create_user("project-import@test.com", "project-import")

    {:ok, installation} =
      Installations.create_installation(user.account, %{
        github_installation_id: 42,
        github_account_login: "acme",
        github_account_type: "Organization",
        github_account_id: 4242
      })

    attrs =
      valid_attrs(%{
        github_repo_id: 999,
        github_repo_full_name: "acme/imported",
        github_repo_default_branch: "main"
      })

    assert {:ok, project} =
             TestHelpers.expect_event(
               "project.created",
               fn ->
                 Projects.create_project_from_github(user.account, installation.id, attrs,
                   actor: user,
                   via: :mcp
                 )
               end,
               %{
                 :account_id => user.account.id,
                 :user_id => user.id,
                 {:opt, :via} => :mcp,
                 {:opt, :resource_type} => "project",
                 {:opt, :summary} => fn summary -> summary =~ "Imported project" end
               }
             )

    assert project.github_repo_full_name == "acme/imported"
  end

  test "update_project/3 updates settings and emits an event" do
    user = TestHelpers.create_user("project-update@test.com", "project-update")
    {:ok, project} = Projects.create_project(user.account, valid_attrs())

    assert {:ok, updated} =
             TestHelpers.expect_event(
               "project.updated",
               fn ->
                 Projects.update_project(project, %{name: "Renamed", description: "Updated"},
                   actor: user,
                   via: :api
                 )
               end,
               %{
                 :account_id => user.account.id,
                 :user_id => user.id,
                 {:opt, :via} => :api,
                 {:opt, :resource_type} => "project"
               }
             )

    assert updated.name == "Renamed"
    assert updated.description == "Updated"
  end

  test "get_project/2 returns only projects for the given account" do
    owner = TestHelpers.create_user("project-get@test.com", "project-get")
    other = TestHelpers.create_user("project-get-other@test.com", "project-get-other")

    {:ok, project} =
      Projects.create_project(owner.account, valid_attrs(%{handle: "owned-project"}))

    assert Projects.get_project(owner.account, "owned-project").id == project.id
    assert Projects.get_project(other.account, "owned-project") == nil
  end

  test "list_projects/2 returns only account projects" do
    owner = TestHelpers.create_user("project-list@test.com", "project-list")
    other = TestHelpers.create_user("project-list-other@test.com", "project-list-other")

    {:ok, _} =
      Projects.create_project(owner.account, valid_attrs(%{handle: "alpha", name: "Alpha"}))

    {:ok, _} =
      Projects.create_project(owner.account, valid_attrs(%{handle: "beta", name: "Beta"}))

    {:ok, _} =
      Projects.create_project(other.account, valid_attrs(%{handle: "other", name: "Other"}))

    assert {:ok, {projects, meta}} = Projects.list_projects(owner.account)
    assert meta.total_count == 2
    assert Enum.map(projects, & &1.handle) == ["alpha", "beta"]
  end

  test "update_project_setup_status/3 persists the status and error" do
    user = TestHelpers.create_user("project-setup@test.com", "project-setup")
    {:ok, project} = Projects.create_project(user.account, valid_attrs())

    assert {:ok, updated} = Projects.update_project_setup_status(project, "failed", "boom")
    assert updated.setup_status == "failed"
    assert updated.setup_error == "boom"

    assert Repo.get!(Glossia.Accounts.Project, project.id).setup_status == "failed"
  end

  test "complete_project_setup/3 persists the pull request with the completed status" do
    user = TestHelpers.create_user("project-setup-pr@test.com", "project-setup-pr")

    {:ok, project} =
      Projects.create_project(
        user.account,
        valid_attrs(%{setup_status: "running", github_repo_id: 7_001})
      )

    assert {:ok, completed} =
             Projects.complete_project_setup(project, nil, %{
               number: 42,
               url: "https://github.com/example/product/pull/42",
               state: "open"
             })

    assert completed.setup_status == "completed"
    assert completed.setup_pull_request_number == 42
    assert completed.setup_pull_request_url == "https://github.com/example/product/pull/42"
    assert completed.setup_pull_request_state == "open"
    assert is_nil(completed.setup_pull_request_merged_at)
  end

  test "update_setup_pull_request_state/4 matches the repository and pull request number" do
    user = TestHelpers.create_user("project-pr-state@test.com", "project-pr-state")

    {:ok, project} =
      Projects.create_project(
        user.account,
        valid_attrs(%{
          github_repo_id: 7_002,
          setup_status: "completed",
          setup_pull_request_number: 17,
          setup_pull_request_url: "https://github.com/example/product/pull/17",
          setup_pull_request_state: "open"
        })
      )

    merged_at = ~U[2026-07-22 16:30:00.000000Z]

    assert {:ok, merged} =
             Projects.update_setup_pull_request_state(7_002, 17, "merged", merged_at)

    assert merged.id == project.id
    assert merged.setup_pull_request_state == "merged"
    assert merged.setup_pull_request_merged_at == merged_at

    assert {:error, :setup_pull_request_not_found} =
             Projects.update_setup_pull_request_state(7_002, 18, "closed")
  end

  test "backfill_setup_pull_request/2 records a historical setup pull request once" do
    user = TestHelpers.create_user("project-pr-backfill@test.com", "project-pr-backfill")

    {:ok, project} =
      Projects.create_project(
        user.account,
        valid_attrs(%{github_repo_id: 7_003, setup_status: "completed"})
      )

    assert {:ok, backfilled} =
             Projects.backfill_setup_pull_request(project, %{
               number: 92,
               url: "https://github.com/glossia/glossia/pull/92"
             })

    assert backfilled.setup_pull_request_number == 92
    assert backfilled.setup_pull_request_state == "open"

    assert {:ok, unchanged} =
             Projects.backfill_setup_pull_request(backfilled, %{
               number: 93,
               url: "https://github.com/glossia/glossia/pull/93"
             })

    assert unchanged.setup_pull_request_number == 92
    assert unchanged.setup_pull_request_url == "https://github.com/glossia/glossia/pull/92"
  end

  test "retry_project_setup/1 only claims the persisted failed state once" do
    user = TestHelpers.create_user("project-retry@test.com", "project-retry")
    {:ok, project} = Projects.create_project(user.account, valid_attrs())
    {:ok, failed} = Projects.update_project_setup_status(project, "failed", "boom")
    stale = failed

    assert {:ok, pending} = Projects.retry_project_setup(failed)
    assert pending.setup_status == "pending"

    sandbox_id = Ecto.UUID.generate()
    assert {:ok, claimed} = Projects.replace_project_sandbox_id(pending, nil, sandbox_id)
    assert {:ok, _running} = Projects.update_project_setup_status(claimed, "running")

    assert {:error, :setup_not_failed} = Projects.retry_project_setup(stale)

    persisted = Repo.get!(Glossia.Accounts.Project, project.id)
    assert persisted.setup_status == "running"
    assert persisted.setup_sandbox_id == sandbox_id
  end

  test "discard_failed_project_setup/1 deletes only a failed provisional project" do
    user = TestHelpers.create_user("project-discard@test.com", "project-discard")
    {:ok, project} = Projects.create_project(user.account, valid_attrs())

    assert {:error, :setup_not_failed} = Projects.discard_failed_project_setup(project)
    assert Repo.get!(Glossia.Accounts.Project, project.id)

    {:ok, failed} = Projects.update_project_setup_status(project, "failed", "boom")

    assert {:ok, discarded} = Projects.discard_failed_project_setup(failed)
    assert discarded.id == project.id
    refute Repo.get(Glossia.Accounts.Project, project.id)
  end

  test "discard_pending_project_setup/1 does not delete an active setup" do
    user = TestHelpers.create_user("project-discard-pending@test.com", "project-discard-pending")

    {:ok, project} =
      Projects.create_project(user.account, valid_attrs(%{setup_status: "pending"}))

    {:ok, running} = Projects.update_project_setup_status(project, "running")

    assert {:error, :setup_not_pending} = Projects.discard_pending_project_setup(running)
    assert Repo.get!(Glossia.Accounts.Project, project.id).setup_status == "running"
  end

  test "reset_project_setup_for_recovery preserves a resumable sandbox" do
    user = TestHelpers.create_user("project-recovery@test.com", "project-recovery")
    {:ok, project} = Projects.create_project(user.account, valid_attrs())
    {:ok, running} = Projects.update_project_setup_status(project, "running")
    sandbox_id = Ecto.UUID.generate()
    {:ok, running} = Projects.replace_project_sandbox_id(running, nil, sandbox_id)

    assert {:ok, recovered} = Projects.reset_project_setup_for_recovery(running)
    assert recovered.setup_status == "pending"
    assert recovered.setup_sandbox_id == sandbox_id
  end

  test "list_imported_github_repositories/1 returns only imported repos for the account" do
    %{account: account} = TestHelpers.create_user("projects-owner@test.com", "projects-owner")

    %{account: other_account} =
      TestHelpers.create_user("projects-other@test.com", "projects-other")

    assert {:ok, imported_project} =
             Projects.create_project(account, %{
               handle: "imported-project",
               name: "Imported Project",
               github_repo_id: 101_001,
               github_repo_full_name: "acme/imported-project"
             })

    assert {:ok, _manual_project} =
             Projects.create_project(account, %{
               handle: "manual-project",
               name: "Manual Project"
             })

    assert {:ok, _other_account_project} =
             Projects.create_project(other_account, %{
               handle: "other-project",
               name: "Other Project",
               github_repo_id: 202_002,
               github_repo_full_name: "other/other-project"
             })

    assert Projects.list_imported_github_repositories(account) == [
             %{
               github_repo_id: imported_project.github_repo_id,
               github_repo_full_name: imported_project.github_repo_full_name
             }
           ]
  end
end
