defmodule GlossiaWeb.DashboardLiveAnalyticsTest do
  use GlossiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mimic

  alias Glossia.Analytics.Settings
  alias Glossia.Projects
  alias Glossia.Repo
  alias Glossia.TestHelpers

  setup :verify_on_exit!

  setup %{conn: conn} do
    user = TestHelpers.create_user("dashboard-analytics@test.com", "dashboard-analytics")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "analytics",
        name: "Analytics"
      })

    %{conn: init_test_session(conn, %{user_id: user.id}), project: project, user: user}
  end

  test "shows setup as an empty state linked to analytics settings", %{
    conn: conn,
    project: project,
    user: user
  } do
    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/analytics")

    assert has_element?(
             view,
             "#analytics-setup-empty-state .dashboard-empty-state",
             "Set up web analytics"
           )

    assert has_element?(
             view,
             "#analytics-setup-empty-state a[href='/#{user.account.handle}/#{project.handle}/-/settings/analytics']",
             "Open analytics settings"
           )
  end

  test "renders analytics configuration on its own settings page", %{
    conn: conn,
    project: project,
    user: user
  } do
    assert {:ok, _settings} =
             Settings.upsert_for_project(project.id, %{domain: "example.com"})

    {:ok, view, html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/settings/analytics")

    assert has_element?(view, "#analytics-settings-form")
    assert has_element?(view, "#analytics-domain[value='example.com']")
    assert has_element?(view, "#analytics-snippet", "https://glossia.ai/assets/glossia-web.js")
    refute html =~ "cdn.glossia.ai"
    assert html =~ ~s(id="project-settings-navigation")

    assert html =~
             ~s(<a href="/#{user.account.handle}/#{project.handle}/-/settings" data-part="link">)

    assert html =~
             ~s(href="/#{user.account.handle}/#{project.handle}/-/settings/analytics")

    refute html =~ ~s(<span data-part="label">General</span>)
  end

  test "verifies ownership from settings and unlocks the analytics dashboard", %{
    conn: conn,
    project: project,
    user: user
  } do
    domain = "verified-#{project.id}.example.com"
    {:ok, settings} = Settings.upsert_for_project(project.id, %{domain: domain})

    expect(Glossia.Analytics.Verification, :verify, fn received_domain, token ->
      assert received_domain == domain
      assert token == settings.verification_token
      :ok
    end)

    {:ok, view, _html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/settings/analytics")

    assert has_element?(view, "#analytics-verification-meta-tag", settings.verification_token)
    view |> element("#verify-analytics-domain-btn") |> render_click()

    assert Settings.get_for_project(project.id).verified_at
    assert has_element?(view, "#analytics-domain-verification", "Domain verified")
    refute has_element?(view, "#verify-analytics-domain-btn")
    assert Settings.fetch_for_collection(domain).project_id == project.id

    {:ok, dashboard, _html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/analytics")

    refute has_element?(dashboard, "#analytics-setup-empty-state")
    assert has_element?(dashboard, "#analytics-traffic")

    view
    |> form("#analytics-settings-form", analytics: %{domain: "changed.example.com"})
    |> render_submit()

    updated = Settings.get_for_project(project.id)
    refute updated.verified_at
    refute updated.verification_token == settings.verification_token
    assert has_element?(view, "#analytics-verification-meta-tag", updated.verification_token)
    assert has_element?(view, "#verify-analytics-domain-btn")
  end

  test "failed ownership verification keeps collection and dashboard gated", %{
    conn: conn,
    project: project,
    user: user
  } do
    domain = "unverified-#{project.id}.example.com"
    {:ok, _settings} = Settings.upsert_for_project(project.id, %{domain: domain})
    expect(Glossia.Analytics.Verification, :verify, fn ^domain, _token -> :error end)

    {:ok, view, _html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/settings/analytics")

    view |> element("#verify-analytics-domain-btn") |> render_click()

    assert render(view) =~ "Verification not found"
    assert has_element?(view, "#verify-analytics-domain-btn")
    refute Settings.get_for_project(project.id).verified_at
    refute Settings.fetch_for_collection(domain)
  end

  test "members cannot verify a domain through a forged dashboard event", %{
    conn: conn,
    project: project,
    user: user
  } do
    {:ok, _settings} =
      Settings.upsert_for_project(project.id, %{domain: "member-#{project.id}.example.com"})

    reject(Glossia.Analytics.Verification, :verify, 2)
    member = TestHelpers.create_user("analytics-member@test.com", "analytics-member")
    organization = Glossia.Organizations.get_organization_for_account(user.account)
    {:ok, _membership} = Glossia.Organizations.add_member(organization, member, "member")
    conn = init_test_session(conn, %{user_id: member.id})

    {:ok, view, _html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/analytics")

    render_click(view, "verify_analytics_domain")
    assert has_element?(view, "#flash-error", "You don't have permission.")
    refute Settings.get_for_project(project.id).verified_at
  end

  test "verification requires saved settings", %{conn: conn, project: project, user: user} do
    {:ok, view, _html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/settings/analytics")

    refute has_element?(view, "#analytics-domain-verification")
    assert render_click(view, "verify_analytics_domain") =~ "Save an analytics domain"
  end

  test "keeps analytics configuration out of general project settings", %{
    conn: conn,
    project: project,
    user: user
  } do
    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/settings")

    assert has_element?(view, "#project-settings-form")
    refute has_element?(view, "#analytics-settings-form")
  end

  test "keeps the world map visible with an empty priority table", %{
    conn: conn,
    project: project,
    user: user
  } do
    {:ok, settings} = Settings.upsert_for_project(project.id, %{domain: "example.com"})

    settings
    |> Ecto.Changeset.change(%{
      verified_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
    })
    |> Repo.update!()

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/analytics")

    assert has_element?(
             view,
             "[data-part='localization-priority-content'] .noora-table-empty-state",
             "No locale-gap visits"
           )

    assert has_element?(
             view,
             "#top-pages-table .noora-table-empty-state",
             "No pageviews yet"
           )

    assert has_element?(
             view,
             "#top-countries-table .noora-table-empty-state",
             "No country data yet"
           )

    assert has_element?(view, "#localization-priority-map[phx-hook='LocalizationPriorityMap']")
    assert has_element?(view, "#analytics-traffic[phx-hook='AnalyticsTraffic']")
    assert has_element?(view, "#analytics-traffic-canvas[data-granularity='day']")
    refute render(view) =~ "Traffic by hour"
    refute has_element?(view, "[data-part='localization-priority'] [data-part='legend-bar']")
  end
end
