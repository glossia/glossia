defmodule GlossiaEnterpriseWeb.AuditLogsLiveTest do
  use GlossiaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  require Ecto.Query

  alias Glossia.{Events, Organizations, TestHelpers}

  setup %{conn: conn} do
    admin = TestHelpers.create_user("audit-ui@example.test", "audit-ui")

    {:ok, %{account: account, organization: organization}} =
      Organizations.create_organization(admin, %{
        handle: "audit-ui-#{System.unique_integer([:positive])}"
      })

    %{
      conn: init_test_session(conn, %{user_id: admin.id}),
      account: account,
      organization: organization,
      admin: admin
    }
  end

  test "administrators discover audit logs and can share search, filters, and sorting", %{
    conn: conn,
    account: account,
    admin: admin
  } do
    Events.emit("project.created", account, admin, summary: "Created Apollo project")
    {:ok, view, _} = live(conn, ~p"/#{account.handle}/-/audit-logs")
    assert has_element?(view, "#account-section-organization[data-open]")

    for path <- [
          ~p"/#{account.handle}/-/members",
          ~p"/#{account.handle}/-/settings/authentication",
          ~p"/#{account.handle}/-/audit-logs"
        ] do
      assert has_element?(view, ~s(#account-section-organization a[href="#{path}"]))
    end

    assert has_element?(
             view,
             ~s(#account-section-organization a[href="#{~p"/#{account.handle}/-/audit-logs"}"] [data-selected])
           )

    refute has_element?(view, "#account-section-enterprise")
    refute has_element?(view, "#audit-logs-page > .noora-badge", "Enterprise")
    assert has_element?(view, "#audit-events", "Created Apollo project")

    view |> form("#audit-search", q: "Apollo") |> render_change()
    assert_patch(view, ~p"/#{account.handle}/-/audit-logs?#{%{"q" => "Apollo", "page" => "1"}}")
    assert has_element?(view, "#audit-events", "Created Apollo project")
    refute has_element?(view, "#audit-events", "organization.created")

    render_hook(view, "add_filter", %{"value" => "event"})

    render_hook(view, "update_filter", %{
      "type" => "change_value",
      "payload_filter_id" => "event",
      "value" => "project.created"
    })

    assert has_element?(view, "#event", "project.created")

    view |> element(~s(#audit-events thead a), "Event") |> render_click()
    assert has_element?(view, "#audit-events", "Created Apollo project")

    params = %{
      "q" => "Apollo",
      "sort" => "name",
      "dir" => "desc",
      "page" => "1",
      "filter_event_op" => "==",
      "filter_event_val" => "project.created"
    }

    assert_patch(view, ~p"/#{account.handle}/-/audit-logs?#{params}")
    {:ok, reloaded, _} = live(conn, ~p"/#{account.handle}/-/audit-logs?#{params}")
    assert has_element?(reloaded, "#audit-query[value=Apollo]")
    assert has_element?(reloaded, "#event", "project.created")

    render_hook(reloaded, "update_filter", %{
      "type" => "change_operator",
      "payload_filter_id" => "event",
      "value" => "!="
    })

    assert has_element?(reloaded, "#audit-events", "No matching events")
    render_hook(reloaded, "update_filter", %{"type" => "delete", "payload_filter_id" => "event"})
    refute has_element?(reloaded, "#event")
    assert has_element?(reloaded, "#audit-events", "Created Apollo project")

    view |> form("#audit-search", q: "missing event") |> render_change()
    assert has_element?(view, "#audit-events", "No matching events")
  end

  test "accounts without earlier history retain the card and explain when recording starts", %{
    conn: conn,
    account: account,
    admin: admin
  } do
    # An account that predates enabling Enterprise has no historical records.
    history = Ecto.Query.where(GlossiaEnterprise.Audit.Event, account_id: ^account.id)
    Glossia.Repo.delete_all(history)
    {:ok, view, _} = live(conn, ~p"/#{account.handle}/-/audit-logs")
    assert has_element?(view, "#audit-events", "No audit events yet")
    assert has_element?(view, "#audit-events", "Earlier activity is not backfilled")
    Events.emit("project.created", account, admin, summary: "First recorded project")
    {:ok, view, _} = live(conn, ~p"/#{account.handle}/-/audit-logs")
    assert has_element?(view, "#audit-events", "First recorded project")
    refute has_element?(view, "#audit-events", "No audit events yet")
  end

  test "public account visibility never grants audit access to ordinary members", %{
    conn: conn,
    account: account,
    organization: organization
  } do
    member = TestHelpers.create_user("audit-reader@example.test", "audit-reader")
    {:ok, _} = Organizations.add_member(organization, member)
    {:ok, _} = Organizations.update_organization(organization, %{visibility: "public"})
    conn = init_test_session(conn, %{user_id: member.id})
    {:ok, view, _} = live(conn, ~p"/#{account.handle}")
    refute has_element?(view, ~s(a[href="#{~p"/#{account.handle}/-/audit-logs"}"]))
    assert_raise Ecto.NoResultsError, fn -> live(conn, ~p"/#{account.handle}/-/audit-logs") end
  end
end
