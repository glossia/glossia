defmodule Glossia.ProjectsTest do
  use Glossia.DataCase, async: true

  alias Glossia.Projects
  alias Glossia.TestHelpers

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
