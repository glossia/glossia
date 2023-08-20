defmodule Glossia.ProjectsTest do
  use Glossia.DataCase

  alias Glossia.Repo
  alias Glossia.Projects

  describe "find_project_by_repository" do
    test "returns the project if it exists" do
      # Given
      {:ok, project} = Glossia.ProjectsFixtures.project_fixture()

      # When
      got =
        Projects.find_project_by_repository(%{
          vcs_id: project.vcs_id,
          vcs_platform: project.vcs_platform
        })

      # Then
      assert got.id == project.id
      assert got.handle == project.handle
      assert got.vcs_id == project.vcs_id
    end
  end

  describe "generate_token_for_project" do
    test "returns a token for the project" do
      # Given
      {:ok, project} = Glossia.ProjectsFixtures.project_fixture()

      # When
      got = Projects.generate_token_for_project(project)

      # Then
      assert got != nil
    end
  end

  describe "get_project_from_token" do
    test "it returns nil if the project doesn't exist" do
      # Given
      {:ok, project} = Glossia.ProjectsFixtures.project_fixture()

      # When
      token = Projects.generate_token_for_project(project)
      {:ok, _} = Repo.delete(project)
      got_project = Projects.get_project_from_token(token)

      # Then
      assert got_project == nil
    end

    test "it returns the project if the project exists" do
      # Given
      {:ok, project} = Glossia.ProjectsFixtures.project_fixture()

      # When
      token = Projects.generate_token_for_project(project)
      got_project = Projects.get_project_from_token(token)

      # Then
      assert got_project.id == project.id
    end
  end
end
