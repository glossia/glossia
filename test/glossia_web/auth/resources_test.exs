defmodule GlossiaWeb.Auth.ResourcesTest do
  # https://thoughtbot.com/blog/testing-elixir-plugs
  use GlossiaWeb.ConnCase
  alias GlossiaWeb.Auth.Resources

  test "returns a 401 response if the authorization header is missing", %{conn: conn} do
    # Given
    opts = Resources.init(:authenticated_project)

    # When
    conn = conn |> Resources.call(opts)

    # Then
    assert conn.assigns[:authenticated_project] == nil
  end

  test "doesn't assign a project if the token is invalid", %{conn: conn} do
    # Given
    opts = Resources.init(:authenticated_project)

    # When
    conn = conn |> put_req_header("authorization", "Bearer invalid") |> Resources.call(opts)

    # Then
    assert conn.assigns[:authenticated_project] == nil
  end

  test "it assigns the project if it exists", %{conn: conn} do
    # Given
    {:ok, project} = Glossia.ProjectsFixtures.project_fixture()
    token = Glossia.Projects.generate_token_for_project(project)
    opts = Resources.init(:authenticated_project)

    # When
    conn = conn |> put_req_header("authorization", "Bearer #{token}") |> Resources.call(opts)

    # Then
    assert conn.assigns[:authenticated_project].id == project.id
  end
end
