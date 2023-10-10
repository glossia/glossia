defmodule Glossia.Foundation.Projects.Web.Plugs.SaveLastVisitedProjectPlugTest do
  # Modules
  use Glossia.Web.ConnCase
  alias Glossia.Repo
  alias Glossia.Foundation.AccountsFixtures
  alias Glossia.Foundation.ProjectsFixtures
  alias Glossia.Foundation.Projects.Web.Plugs.SaveLastVisitedProjectPlug
  alias Glossia.Foundation.Accounts.Web.Helpers.Auth

  test "call when the user can read the project", %{conn: conn} do
    # Given
    plug = SaveLastVisitedProjectPlug.init([])
    user = AccountsFixtures.user_fixture() |> Repo.preload(:account)
    project = ProjectsFixtures.project_fixture(%{account_id: user.account.id})
    conn = conn |> assign(:url_project, project) |> Auth.assign_authenticated_user(user)

    # When
    _ = SaveLastVisitedProjectPlug.call(conn, plug)

    # Then
    user = user |> Repo.reload()
    assert user.last_visited_project_id == project.id
  end

  test "call when the user can't read the project", %{conn: conn} do
    # Given
    plug = SaveLastVisitedProjectPlug.init([])
    user = AccountsFixtures.user_fixture() |> Repo.preload(:account)
    project = ProjectsFixtures.project_fixture()
    conn = conn |> assign(:url_project, project) |> Auth.assign_authenticated_user(user)

    # When
    _ = SaveLastVisitedProjectPlug.call(conn, plug)

    # Then
    user = user |> Repo.reload()
    assert user.last_visited_project_id == nil
  end
end
