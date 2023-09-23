defmodule Glossia.Foundation.Projects.Core.RepositoryTest do
  use Glossia.DataCase
  alias Glossia.Foundation.ProjectsFixtures
  alias Glossia.Foundation.AccountsFixtures
  alias Glossia.Foundation.Projects.Core.Repository

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
