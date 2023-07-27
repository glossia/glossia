defmodule Glossia.ProjectsTest do
  use Glossia.DataCase

  alias Glossia.Projects

  describe "find_project_by_repository" do
    test "returns the project if it exists" do
      # Given
      {:ok, project} = Glossia.ProjectsFixtures.project_fixture()

      # When
      got = Projects.find_project_by_repository(project.vcs_id, project.vcs_platform)

      # Then
      assert got.id == project.id
      assert got.handle == project.handle
      assert got.vcs_id == project.vcs_id
    end
  end
end
