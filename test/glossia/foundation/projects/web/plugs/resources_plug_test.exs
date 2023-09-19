defmodule Glossia.Foundation.Projects.Web.Plugs.ResourcesPlugTest do
  # https://thoughtbot.com/blog/testing-elixir-plugs
  use Glossia.Web.ConnCase
  alias Glossia.Foundation.Database.Core.Repo
  alias Glossia.Foundation.ProjectsFixtures
  alias Glossia.Foundation.Projects.Web.Plugs.ResourcesPlug

  describe ":url_project" do
    test "assigns the project when the project exists", %{conn: conn} do
      # Given
      project = ProjectsFixtures.project_fixture()
      project = project |> Repo.preload(:account)
      project_handle = project.handle
      owner_handle = project.account.handle
      opts = ResourcesPlug.init(:url_project)
      conn = %{conn | params: Map.put(conn.params, "owner_handle", owner_handle)}
      conn = %{conn | params: Map.put(conn.params, "project_handle", project_handle)}

      # When
      conn =
        conn
        |> ResourcesPlug.call(opts)

      # Then
      assert conn.assigns[:url_project].id == project.id
    end

    test "doesn't assign the project if it doesn't exist", %{conn: conn} do
      # Given
      project_handle = "invalid"
      owner_handle = "non_existing"
      opts = ResourcesPlug.init(:url_project)
      conn = %{conn | params: Map.put(conn.params, "owner_handle", owner_handle)}
      conn = %{conn | params: Map.put(conn.params, "project_handle", project_handle)}

      # When
      conn =
        conn
        |> ResourcesPlug.call(opts)

      # Then
      assert conn.assigns[:url_project] == nil
    end
  end

  describe ":authenticated_project" do
    test "returns a 401 response if the authorization header is missing", %{conn: conn} do
      # Given
      opts = ResourcesPlug.init(:authenticated_project)

      # When
      conn = conn |> ResourcesPlug.call(opts)

      # Then
      assert conn.assigns[:authenticated_project] == nil
    end

    test "doesn't assign a project if the token is invalid", %{conn: conn} do
      # Given
      opts = ResourcesPlug.init(:authenticated_project)

      # When
      conn = conn |> put_req_header("authorization", "Bearer invalid") |> ResourcesPlug.call(opts)

      # Then
      assert conn.assigns[:authenticated_project] == nil
    end

    test "it assigns the project if it exists", %{conn: conn} do
      # Given
      project = Glossia.Foundation.ProjectsFixtures.project_fixture()
      token = Glossia.Foundation.Projects.Core.generate_token_for_project(project)
      opts = ResourcesPlug.init(:authenticated_project)

      # When
      conn =
        conn |> put_req_header("authorization", "Bearer #{token}") |> ResourcesPlug.call(opts)

      # Then
      assert conn.assigns[:authenticated_project].id == project.id
    end
  end
end
