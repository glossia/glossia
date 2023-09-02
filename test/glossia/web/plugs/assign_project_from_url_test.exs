defmodule Glossia.Web.Plugs.AssignProjectFromURLPlugTest do
  # https://thoughtbot.com/blog/testing-elixir-plugs
  use Glossia.Web.ConnCase
  alias Glossia.ProjectsFixtures
  alias Glossia.Foundation.Database.Core.Repo
  alias Glossia.Web.Plugs.AssignProjectFromURLPlug

  test "assigns the project when the project exists", %{conn: conn} do
    # Given
    {:ok, project} = ProjectsFixtures.project_fixture()
    project = project |> Repo.preload(:account)
    project_handle = project.handle
    owner_handle = project.account.handle
    opts = AssignProjectFromURLPlug.init([])
    conn = %{conn | params: Map.put(conn.params, "owner_handle", owner_handle)}
    conn = %{conn | params: Map.put(conn.params, "project_handle", project_handle)}

    # When
    conn =
      conn
      |> AssignProjectFromURLPlug.call(opts)

    # Then
    assert conn.assigns[:url_project].id == project.id
  end

  test "doesn't assign the project if it doesn't exist", %{conn: conn} do
    # Given
    project_handle = "invalid"
    owner_handle = "non_existing"
    opts = AssignProjectFromURLPlug.init([])
    conn = %{conn | params: Map.put(conn.params, "owner_handle", owner_handle)}
    conn = %{conn | params: Map.put(conn.params, "project_handle", project_handle)}

    # When
    conn =
      conn
      |> AssignProjectFromURLPlug.call(opts)

    # Then
    assert conn.assigns[:url_project] == nil
  end
end
