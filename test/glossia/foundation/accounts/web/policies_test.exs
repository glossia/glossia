defmodule Glossia.Localizations.PoliciesTest do
  # https://thoughtbot.com/blog/testing-elixir-plugs
  use Glossia.Web.ConnCase
  alias Glossia.Localizations.Policies

  describe "localization request" do
    test "authorized? returns true when the current and url projects are the same", %{conn: conn} do
      # Given
      project = Glossia.Foundation.ProjectsFixtures.project_fixture()
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
      url_project = Glossia.Foundation.ProjectsFixtures.project_fixture()
      authenticated_project = Glossia.Foundation.ProjectsFixtures.project_fixture()

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
