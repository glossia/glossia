defmodule GlossiaWeb.QualityLiveTest do
  use GlossiaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Glossia.Quality
  alias Glossia.TestHelpers

  setup %{conn: conn} do
    user = TestHelpers.create_user("quality-live@example.com", "quality-live")

    {:ok, project} =
      Glossia.Projects.create_project(user.account, %{
        handle: "localized-site",
        name: "Localized site"
      })

    %{conn: init_test_session(conn, %{user_id: user.id}), project: project, user: user}
  end

  test "configures locale sites and renders the project QA surface", %{
    conn: conn,
    project: project,
    user: user
  } do
    settings_path =
      ~p"/#{user.account.handle}/#{project.handle}/-/qa/settings"

    {:ok, settings, html} = live(conn, settings_path)

    assert has_element?(settings, "#quality-profile-form")
    assert html =~ "QA settings"
    assert html =~ ~s(href="/#{user.account.handle}/#{project.handle}/-/qa")

    settings
    |> form("#quality-profile-form", %{
      "profile" => %{
        "site_url" => "https://example.com"
      }
    })
    |> render_submit()

    assert render(settings) =~ "QA settings saved."
    assert Quality.get_profile(project).locale_origins == %{"en" => "https://example.com"}
    assert Quality.get_profile(project).seed_paths == ["/"]

    {:ok, overview, overview_html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/qa")

    assert has_element?(overview, "#quality-runs-table")
    assert has_element?(overview, "#quality-findings-table")
    assert overview_html =~ "Reviewed project memory"
    refute overview_html =~ "Configuration required"
  end

  test "streams captures and annotations into a replayable review session", %{
    conn: conn,
    project: project,
    user: user
  } do
    assert {:ok, _profile} =
             Quality.upsert_profile(project, %{
               source_locale: "en",
               locale_origins: %{
                 "en" => "https://example.com",
                 "es" => "https://example.com/es"
               },
               seed_paths: ["/settings"],
               max_pages: 5
             })

    assert {:ok, run} = Quality.create_run(user.account, project, user, enqueue: false)
    assert {:ok, running} = Quality.mark_run_running(run, nil)

    {:ok, view, html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/qa/runs/#{run.id}")

    assert html =~ "Review session"
    assert html =~ "Preparing the browser"

    assert has_element?(
             view,
             "#quality-session-events [data-part='timeline-item']",
             "Review session started"
           )

    assert {:ok, page} =
             Quality.create_page(running, %{
               locale: "en",
               logical_path: "/settings",
               requested_url: "https://example.com/settings",
               final_url: "https://example.com/settings",
               title: "Account settings",
               document_locale: "en",
               visible_text: "Manage your account settings and notification preferences.",
               alternate_links: %{}
             })

    assert {:ok, _event} =
             Quality.record_session_event(running, %{
               kind: "page_captured",
               label: "Captured en /settings",
               detail: page.title,
               page_id: page.id,
               metadata: %{"locale" => "en", "logical_path" => "/settings"}
             })

    assert render(view) =~ "Page text snapshot"
    assert has_element?(view, "#quality-session-replay[phx-hook]")
    assert has_element?(view, "#quality-session-replay-range[max]")

    assert {:ok, finding} =
             Quality.record_finding(running, page, %{
               check: "wording_consistency",
               category: "language",
               severity: "medium",
               title: "Inconsistent account terminology",
               description: "This page uses a different term for account settings.",
               locale: "en",
               logical_path: "/settings",
               source_text: "Account settings",
               target_text: "Profile preferences"
             })

    assert render(view) =~ "Agent annotations"

    assert has_element?(
             view,
             "#quality-capture-annotations tbody tr",
             "Inconsistent account terminology"
           )

    assert has_element?(
             view,
             "#quality-session-replay [data-part='finding-marker'][data-time]"
           )

    assert has_element?(view, "#quality-finding-actions-#{finding.id}.noora-dropdown")
    assert has_element?(view, "#quality-memory-modal-#{finding.id}.noora-modal")

    refute has_element?(
             view,
             "#quality-findings-table [phx-click='update_finding'].noora-button"
           )

    assert {:ok, _completed} = Quality.complete_run(running)
    assert render(view) =~ "Completed"

    assert has_element?(
             view,
             "#quality-session-events [data-part='timeline-item']",
             "Review session completed"
           )
  end

  test "cancels an interrupted browser review from the run page", %{
    conn: conn,
    project: project,
    user: user
  } do
    assert {:ok, _profile} =
             Quality.upsert_profile(project, %{
               source_locale: "en",
               locale_origins: %{
                 "en" => "https://example.com",
                 "es" => "https://example.com/es"
               },
               seed_paths: ["/"],
               max_pages: 5
             })

    assert {:ok, run} = Quality.create_run(user.account, project, user, enqueue: false)

    {:ok, view, _html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/qa/runs/#{run.id}")

    assert has_element?(view, "[phx-click='cancel_quality_run']", "Cancel run")
    view |> element("[phx-click='cancel_quality_run']") |> render_click()

    assert render(view) =~ "The localization QA run was cancelled."
    assert Quality.get_run!(project, run.id).status == "cancelled"

    assert has_element?(
             view,
             "#quality-session-events [data-part='timeline-item']",
             "Review session cancelled"
           )
  end
end
