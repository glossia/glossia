defmodule GlossiaWeb.DashboardLiveMembersTest do
  use GlossiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Glossia.TestHelpers

  setup %{conn: conn} do
    user = TestHelpers.create_user("dashboard-members@test.com", "dashboard-members")

    %{
      conn: init_test_session(conn, %{user_id: user.id}),
      user: user
    }
  end

  test "uses Noora controls and tables for organization members", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, ~p"/#{user.account.handle}/-/members")

    assert has_element?(view, "#members-page")
    assert has_element?(view, ".noora-text-input #members-search")
    assert has_element?(view, "#members-role-filter.noora-dropdown")
    assert has_element?(view, "#members-tabs .noora-tab-menu-horizontal")
    assert has_element?(view, "#members-table.noora-table")
    assert has_element?(view, "#members-table .noora-avatar")
    assert has_element?(view, "#members-table .noora-badge", "Admin")
    assert has_element?(view, "#invite-member-form #invite-member-modal.noora-modal")
    refute has_element?(view, "#members-page .resource-index")
  end

  test "shows pending invitations in a Noora tab and preserves it while searching", %{
    conn: conn,
    user: user
  } do
    {:ok, view, _html} = live(conn, ~p"/#{user.account.handle}/-/members")

    view
    |> element("#members-tabs a", "Invitations")
    |> render_click()

    assert_patch(view, ~p"/#{user.account.handle}/-/members?tab=invitations")
    assert has_element?(view, "#invitations-table.noora-table")

    assert has_element?(
             view,
             "#invitations-table .noora-table-empty-state",
             "No pending invitations"
           )

    view
    |> form("#members-search-form", %{"search" => "colleague@example.com"})
    |> render_change()

    assert_patch(
      view,
      ~p"/#{user.account.handle}/-/members?#{%{tab: "invitations", iq: "colleague@example.com"}}"
    )

    assert has_element?(view, "#invitations-table.noora-table")
  end
end
