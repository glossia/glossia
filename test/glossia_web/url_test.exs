defmodule GlossiaWeb.URLTest do
  # https://thoughtbot.com/blog/testing-elixir-plugs
  use Glossia.Web.ConnCase
  alias Glossia.Repo
  alias Glossia.ProjectsFixtures
  alias GlossiaWeb.URL

  describe ":load_project plug" do
    test "assigns the project when the project exists", %{conn: conn} do
      # Given
      project = ProjectsFixtures.project_fixture()
      project = project |> Repo.preload(:account)
      project_handle = project.handle
      owner_handle = project.account.handle
      opts = URL.init(:load_project)
      conn = %{conn | params: Map.put(conn.params, "owner_handle", owner_handle)}
      conn = %{conn | params: Map.put(conn.params, "project_handle", project_handle)}

      # When
      conn =
        conn
        |> URL.call(opts)

      # Then
      assert GlossiaWeb.URL.url_project(conn).id == project.id
    end

    test "doesn't assign the project if it doesn't exist", %{conn: conn} do
      # Given
      project_handle = "invalid"
      owner_handle = "non_existing"
      opts = URL.init(:load_project)
      conn = %{conn | params: Map.put(conn.params, "owner_handle", owner_handle)}
      conn = %{conn | params: Map.put(conn.params, "project_handle", project_handle)}

      # When
      conn =
        conn
        |> URL.call(opts)

      # Then
      assert GlossiaWeb.URL.url_project(conn) == nil
    end
  end
end
