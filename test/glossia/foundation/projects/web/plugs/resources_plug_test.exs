defmodule Glossia.Foundation.Projects.Web.Plugs.ResourcesPlugTest do
  # https://thoughtbot.com/blog/testing-elixir-plugs
  use Glossia.Web.ConnCase
  alias Glossia.Foundation.Projects.Web.Plugs.ResourcesPlug

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
    conn = conn |> put_req_header("authorization", "Bearer #{token}") |> ResourcesPlug.call(opts)

    # Then
    assert conn.assigns[:authenticated_project].id == project.id
  end
end
