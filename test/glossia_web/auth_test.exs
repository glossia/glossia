defmodule GlossiaWeb.Plugs.AuthTest do
  # https://thoughtbot.com/blog/testing-elixir-plugs
  use Glossia.Web.ConnCase
  alias GlossiaWeb.Auth

  describe ":load_authenticated_project plug" do
    test "returns a 401 response if the authorization header is missing", %{conn: conn} do
      # Given
      opts = Auth.init(:load_authenticated_project)

      # When
      conn = conn |> Auth.call(opts)

      # Then
      assert Auth.authenticated_project(conn) == nil
    end

    test "doesn't assign a project if the token is invalid", %{conn: conn} do
      # Given
      opts = Auth.init(:load_authenticated_project)

      # When
      conn = conn |> put_req_header("authorization", "Bearer invalid") |> Auth.call(opts)

      # Then
      assert Auth.authenticated_project(conn) == nil
    end

    test "it assigns the project if it exists", %{conn: conn} do
      # Given
      project = Glossia.ProjectsFixtures.project_fixture()
      token = Glossia.Projects.generate_token_for_project(project)
      opts = Auth.init(:load_authenticated_project)

      # When
      conn =
        conn |> put_req_header("authorization", "Bearer #{token}") |> Auth.call(opts)

      # Then
      assert Auth.authenticated_project(conn).id == project.id
    end
  end
end
