defmodule Glossia.Projects.RepositoryTest do
  use Glossia.DataCase
  alias Glossia.ProjectsFixtures
  alias Glossia.AccountsFixtures
  alias Glossia.Projects.Repository

  describe "update_last_visited_project_for_user" do
    test "updates the last visited project" do
      # Given
      user = AccountsFixtures.user_fixture()
      project = ProjectsFixtures.project_fixture()

      # When
      got = Repository.update_last_visited_project_for_user(user, project)

      # Then
      assert got.last_visited_project_id == project.id
    end
  end
end
