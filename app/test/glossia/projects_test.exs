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
