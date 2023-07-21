defmodule Glossia.ProjectsTest do
  use Glossia.DataCase

  alias Glossia.Projects

  describe "find_project_by_repository" do
    test "returns the project if it exists" do
      # Given
      {:ok, project} = Glossia.ProjectsFixtures.project_fixture()

      # When
      got = Projects.find_project_by_repository(project.repository_id, project.vcs)

      # Then
      assert got.id == project.id
      assert got.handle == project.handle
      assert got.repository_id == project.repository_id
    end
  end
end
