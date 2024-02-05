defmodule GlossiaWeb.LiveViewMountablePlugTest do
  use Glossia.Web.ConnCase

  describe "redirect_to_home_if_logged_in plug" do
    test "doesn't redirect if there's no authenticated user", %{conn: conn} do
      # Given
      opts = GlossiaWeb.LiveViewMountablePlug.init(:redirect_to_home_if_logged_in)

      # When
      got = conn |> GlossiaWeb.LiveViewMountablePlug.call(opts)

      # Then
      assert conn == got
    end

    test "redirects to /new if there's an authenticated user and no last visited project", %{
      conn: conn
    } do
      # Given
      opts = GlossiaWeb.LiveViewMountablePlug.init(:redirect_to_home_if_logged_in)
      %{conn: conn} = register_and_log_in_user(%{conn: conn})

      # When
      conn = conn |> GlossiaWeb.LiveViewMountablePlug.call(opts)

      # Then
      assert redirected_to(conn) =~ "/new"
    end

    test "redirects to the most recently visited project if it exists", %{conn: conn} do
      # Given
      opts = GlossiaWeb.LiveViewMountablePlug.init(:redirect_to_home_if_logged_in)
      %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
      project = Glossia.ProjectsFixtures.project_fixture(account_id: user.account.id)
      Glossia.Accounts.update_last_visited_project_for_user(user, project)

      # When
      conn = conn |> GlossiaWeb.LiveViewMountablePlug.call(opts)

      # Then
      assert redirected_to(conn) =~ ~p"/#{user.account.handle}/#{project.handle}"
    end
  end
end
