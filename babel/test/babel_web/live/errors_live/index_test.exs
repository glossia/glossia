defmodule BabelWeb.ErrorsLive.IndexTest do
  use BabelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Babel.Errors
  alias Babel.Organizations
  alias Babel.Repo

  setup do
    suffix = System.unique_integer([:positive])

    {:ok, organization} =
      Organizations.create_organization(%{
        name: "Test org #{suffix}",
        website_url: "https://example-#{suffix}.com",
        state: "customer"
      })

    {:ok, organization: organization}
  end

  test "renders empty state when no issues", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/errors")

    assert html =~ "Errors"
    assert has_element?(view, "#errors")
    assert has_element?(view, "#errors-issues-card")
    assert html =~ "No issues yet"
  end

  test "renders a seeded issue and links to its detail page", %{
    conn: conn,
    organization: organization
  } do
    fingerprint = String.duplicate("a", 64)
    now = DateTime.utc_now()

    id = Errors.Issue.deterministic_id(organization.id, fingerprint)

    {:ok, issue} =
      %Errors.Issue{}
      |> Errors.Issue.changeset(%{
        id: id,
        organization_id: organization.id,
        fingerprint: fingerprint,
        title: "RuntimeError: divide by zero",
        culprit: "MyApp.Math.divide/2",
        level: :error,
        first_seen: now,
        last_seen: now,
        event_count: 3
      })
      |> Repo.insert()

    {:ok, view, html} = live(conn, ~p"/errors")

    assert html =~ "RuntimeError: divide by zero"
    assert html =~ "MyApp.Math.divide/2"

    assert has_element?(
             view,
             ~s{a[data-part="issue-link"][href="/errors/#{issue.id}"]}
           )
  end

  test "resolving an issue via the row action updates its status", %{
    conn: conn,
    organization: organization
  } do
    fingerprint = String.duplicate("b", 64)
    now = DateTime.utc_now()
    id = Errors.Issue.deterministic_id(organization.id, fingerprint)

    {:ok, _issue} =
      %Errors.Issue{}
      |> Errors.Issue.changeset(%{
        id: id,
        organization_id: organization.id,
        fingerprint: fingerprint,
        title: "Warm-up error",
        first_seen: now,
        last_seen: now
      })
      |> Repo.insert()

    {:ok, view, _html} = live(conn, ~p"/errors")

    view
    |> element(~s{button[phx-click="resolve_issue"][phx-value-id="#{id}"]})
    |> render_click()

    updated = Repo.get!(Errors.Issue, id)
    assert updated.status == :resolved

    # After resolve, the Resolve button should be gone; Reopen should appear.
    refute has_element?(view, ~s{button[phx-click="resolve_issue"][phx-value-id="#{id}"]})
    assert has_element?(view, ~s{button[phx-click="unresolve_issue"][phx-value-id="#{id}"]})
  end

  test "single-organization tenancy: seeding sets it as current", %{
    organization: organization
  } do
    assert Errors.LiveHelpers.current_organization().id == organization.id
  end
end
