defmodule Glossia.ProjectsTest do
  use Glossia.DataCase

  alias Glossia.Repo
  alias Glossia.Projects, as: Projects

  describe "find_project_by_repository" do
    test "returns the project if it exists" do
      # Given
      project = Glossia.ProjectsFixtures.project_fixture()

      # When
      got =
        Projects.find_project_by_repository(%{
          id_in_content_platform: project.id_in_content_platform,
          content_platform: project.content_platform
        })

      # Then
      assert got.id == project.id
      assert got.handle == project.handle
      assert got.id_in_content_platform == project.id_in_content_platform
    end
  end

  describe "generate_token_for_project" do
    test "returns a token for the project" do
      # Given
      project = Glossia.ProjectsFixtures.project_fixture()

      # When
      got = Projects.generate_token_for_project(project)

      # Then
      assert got != nil
    end
  end

  describe "find_project_by_owner_and_project_handle" do
    test "it returns the project if it exists" do
      # Given
      project = Glossia.ProjectsFixtures.project_fixture()
      project = project |> Repo.preload(:account)

      # When
      got_project =
        Projects.find_project_by_owner_and_project_handle(
          project.account.handle,
          project.handle
        )

      # Then
      assert project.id == got_project.id
    end
  end
end
