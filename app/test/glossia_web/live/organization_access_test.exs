defmodule GlossiaWeb.OrganizationAccessTest do
  use GlossiaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias Glossia.{Organizations, TestHelpers}

  test "permission areas remain editable by administrators in both editions", %{conn: conn} do
    admin = TestHelpers.create_user("admin@example.test", "admin")
    member = TestHelpers.create_user("member@example.test", "member")

    {:ok, %{organization: organization, account: account}} =
      Organizations.create_organization(admin, %{
        handle: "permissions-#{System.unique_integer([:positive])}"
      })

    {:ok, _} = Organizations.add_member(organization, member)
    conn = init_test_session(conn, %{user_id: admin.id})
    {:ok, view, _} = live(conn, ~p"/#{account.handle}/-/members/#{member.id}/permissions")
    render_hook(view, "set_group:project", %{"checked" => true})
    render_hook(view, "save", %{})
    assert "project:write" in Organizations.get_membership(organization, member).scopes
    render_hook(view, "set_group:project", %{"checked" => false})
    render_hook(view, "save", %{})
    refute "project:read" in Organizations.get_membership(organization, member).scopes

    assert_raise Ecto.NoResultsError, fn ->
      live(
        init_test_session(conn, %{user_id: member.id}),
        ~p"/#{account.handle}/-/members/#{member.id}/permissions"
      )
    end
  end
end
