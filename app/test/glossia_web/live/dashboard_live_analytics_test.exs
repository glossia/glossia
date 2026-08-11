defmodule GlossiaWeb.DashboardLiveAnalyticsTest do
  use GlossiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Glossia.Analytics.Settings
  alias Glossia.Projects
  alias Glossia.Repo
  alias Glossia.TestHelpers

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
    assert html =~ ~s(id="project-settings-navigation")

    assert html =~
             ~s(<a href="/#{user.account.handle}/#{project.handle}/-/settings" data-part="link">)

    assert html =~
             ~s(href="/#{user.account.handle}/#{project.handle}/-/settings/analytics")

    refute html =~ ~s(<span data-part="label">General</span>)
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

  test "shows a compact empty state when there are no localization priorities", %{
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

    refute has_element?(view, "#localization-priority-map")
  end
end
