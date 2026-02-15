defmodule GlossiaWeb.Api.ProjectApiControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.Projects
  alias GlossiaWeb.ApiTestHelpers

  @scopes ~w(project:read)

  setup do
    owner = ApiTestHelpers.create_user("project-owner@test.com", "project-owner")
    outsider = ApiTestHelpers.create_user("project-outsider@test.com", "project-outsider")

    {:ok, project} =
      Projects.create_project(owner.account, %{
        handle: "proj-#{System.unique_integer([:positive])}",
        name: "Example Project"
      })

    %{owner: owner, outsider: outsider, project: project}
  end

  describe "GET /api/:handle/projects" do
    test "lists projects when authorized", %{conn: conn, owner: owner, project: project} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(owner, @scopes)
        |> get("/api/#{owner.account.handle}/projects")

      assert %{"projects" => projects} = json_response(conn, 200)
      handles = Enum.map(projects, & &1["handle"])
      assert project.handle in handles
    end

    test "returns 403 when missing required scope", %{conn: conn, owner: owner} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(owner, [])
        |> get("/api/#{owner.account.handle}/projects")

      assert %{"error" => "insufficient_scope", "required_scope" => "project:read"} =
               json_response(conn, 403)
    end

    test "returns 403 for a different account", %{conn: conn, owner: owner, outsider: outsider} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(outsider, @scopes)
        |> get("/api/#{owner.account.handle}/projects")

      assert %{"error" => "not_authorized"} = json_response(conn, 403)
    end
  end
end
