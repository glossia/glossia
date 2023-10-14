defmodule Glossia.Projects.PoliciesTest do
  use Glossia.Web.ConnCase
  alias Glossia.Repo
  alias Glossia.ProjectsFixtures
  alias Glossia.AccountsFixtures
  alias Glossia.Projects.Policies

  describe "authenticated_project_present" do
    test "returns unauthorized if the project is missing" do
      # When/Then
      assert {:error, :unauthorized} == Policies.policy(%{}, :authenticated_project_present)
    end
  end

  describe "{:read, :project}" do
    test "when project and user are absent" do
      assert {:error, :unauthorized} == Policies.policy(%{}, {:read, :project})
    end

    test "when the project is absent" do
      # Given
      user = AccountsFixtures.user_fixture()

      # When/Then
      assert {:error, :unauthorized} == Policies.policy(%{user: user}, {:read, :project})
    end

    test "when the user is absent but the project is public" do
      # Given
      project = ProjectsFixtures.project_fixture(%{visibility: :public})

      # When/Then
      assert :ok == Policies.policy(%{project: project}, {:read, :project})
    end

    test "when the user is absent and the project is private" do
      # Given
      project = ProjectsFixtures.project_fixture(%{visibility: :private})

      # When/Then
      assert {:error, :unauthorized} == Policies.policy(%{project: project}, {:read, :project})
    end

    test "when the user is present but can't access the project's account" do
      # Given
      project = ProjectsFixtures.project_fixture(%{})
      user = AccountsFixtures.user_fixture()

      # When/Then
      assert {:error, :unauthorized} ==
               Policies.policy(%{project: project, user: user}, {:read, :project})
    end

    test "when the user is present and has access to the project's account" do
      # Given
      user = AccountsFixtures.user_fixture() |> Repo.preload(:account)
      project = ProjectsFixtures.project_fixture(%{account_id: user.account.id})

      # When/Then
      assert :ok == Policies.policy(%{project: project, user: user}, {:read, :project})
    end
  end
end
