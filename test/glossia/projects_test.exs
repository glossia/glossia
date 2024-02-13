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
          id_in_content_source_platform: project.id_in_content_source_platform,
          content_source_platform: project.content_source_platform
        })

      # Then
      assert got.id == project.id
      assert got.handle == project.handle
      assert got.id_in_content_source_platform == project.id_in_content_source_platform
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

  describe "get_project_from_token" do
    test "it returns nil if the project doesn't exist" do
      # Given
      project = Glossia.ProjectsFixtures.project_fixture()

      # When
      token = Projects.generate_token_for_project(project)
      {:ok, _} = Repo.delete(project)
      got_project = Projects.get_project_from_token(token)

      # Then
      assert got_project == nil
    end

    test "it returns the project if the project exists" do
      # Given
      project = Glossia.ProjectsFixtures.project_fixture()

      # When
      token = Projects.generate_token_for_project(project)
      got_project = Projects.get_project_from_token(token)

      # Then
      assert got_project.id == project.id
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
