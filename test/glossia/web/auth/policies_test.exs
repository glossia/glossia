defmodule Glossia.Web.Auth.PoliciesTest do
  # https://thoughtbot.com/blog/testing-elixir-plugs
  use Glossia.Web.ConnCase
  alias Glossia.Web.Auth.Policies

  describe "authenticated_project" do
    test "returns unauthorized if the project is missing", %{conn: conn} do
      # Given
      opts = Policies.init(:authenticated_project)

      # When
      conn = conn |> Policies.call(opts)

      # Then
      assert %{
               "errors" => [%{"detail" => "You need to be authenticated to access this resource"}]
             } =
               json_response(conn, 401)
    end
  end

  describe "localization request" do
    test "authorized? returns true when the current and url projects are the same", %{conn: conn} do
      # Given
      {:ok, project} = Glossia.Foundation.ProjectsFixtures.project_fixture()
      conn = conn |> assign(:authenticated_project, project) |> assign(:url_project, project)

      # When
      authorized = conn |> Policies.authorized?({:create, :localization_request})

      # Then
      assert authorized == true
    end

    test "authorized? returns false when the current and url projects are not the same", %{
      conn: conn
    } do
      # Given
      {:ok, url_project} = Glossia.Foundation.ProjectsFixtures.project_fixture()
      {:ok, authenticated_project} = Glossia.Foundation.ProjectsFixtures.project_fixture()

      conn =
        conn
        |> assign(:authenticated_project, authenticated_project)
        |> assign(:url_project, url_project)

      # When
      authorized = conn |> Policies.authorized?({:create, :localization_request})

      # Then
      assert authorized == false
    end
  end
end
