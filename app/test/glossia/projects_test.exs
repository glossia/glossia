defmodule Glossia.ProjectsTest do
  use Glossia.DataCase, async: true

  alias Glossia.Projects
  alias GlossiaWeb.ApiTestHelpers

  test "list_imported_github_repositories/1 returns only imported repos for the account" do
    %{account: account} = ApiTestHelpers.create_user("projects-owner@test.com", "projects-owner")

    %{account: other_account} =
      ApiTestHelpers.create_user("projects-other@test.com", "projects-other")

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

  describe "get_project_by_github_repo_id/1" do
    test "returns the project matching the github_repo_id" do
      %{account: account} =
        ApiTestHelpers.create_user("gh-repo-lookup@test.com", "gh-repo-lookup")

      {:ok, project} =
        Projects.create_project(account, %{
          handle: "gh-project-#{System.unique_integer([:positive])}",
          name: "GH Project",
          github_repo_id: 999_001
        })

      result = Projects.get_project_by_github_repo_id(999_001)
      assert result.id == project.id
      assert result.account.id == account.id
    end

    test "returns nil when no project matches" do
      assert Projects.get_project_by_github_repo_id(0) == nil
    end
  end
end
