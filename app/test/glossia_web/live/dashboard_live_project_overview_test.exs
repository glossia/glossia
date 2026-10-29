defmodule GlossiaWeb.DashboardLiveProjectOverviewTest do
  use GlossiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Glossia.Projects
  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions

  setup %{conn: conn} do
    user = TestHelpers.create_user("project-overview@test.com", "project-overview")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "translated-project",
        name: "Translated project",
        setup_status: "completed",
        setup_target_languages: ["es", "fr"]
      })

    {:ok, translated} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "translated-sha",
        commit_message: "Publish the translated guide",
        status: "completed",
        outcome: "translated",
        translated_content_count: 4,
        content_hit_count: 2,
        source_language: "en",
        target_languages: ["es", "fr"]
      })

    {:ok, _content_hit} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "current-sha",
        commit_message: "Refresh pricing metadata",
        status: "completed",
        outcome: "content_hit",
        content_hit_count: 7,
        source_language: "en",
        target_languages: ["es", "fr"]
      })

    yesterday = DateTime.add(DateTime.utc_now(), -86_400, :second)

    translated
    |> Ecto.Changeset.change(inserted_at: yesterday, updated_at: yesterday)
    |> Glossia.Repo.update!()

    %{
      conn: init_test_session(conn, %{user_id: user.id}),
      project: project,
      user: user
    }
  end

  test "shows translation widgets, daily volume, and outcome details", %{
    conn: conn,
    project: project,
    user: user
  } do
    {:ok, view, _html} = live(conn, "/#{user.account.handle}/#{project.handle}")

    assert has_element?(view, "#translation-runs-widget", "2")
    assert has_element?(view, "#content-hit-rate-widget", "69.2%")
    assert has_element?(view, "#content-hits-widget", "9")
    assert has_element?(view, "#content-misses-widget", "4")
    assert has_element?(view, "#translation-runs-widget-tooltip")
    assert has_element?(view, "#project-translations-card", "Translations")
    assert has_element?(view, "#project-translations-card", "Recent activity")
    assert has_element?(view, "#translation-chart-legend", "Content hits")
    assert has_element?(view, "#translation-chart-legend", "Content misses")
    assert has_element?(view, "#translation-chart-legend [data-color='p50']")
    assert has_element?(view, "#translations-per-day-chart[phx-hook='NooraChart']")

    chart_data =
      view
      |> element("#translations-per-day-chart [data-part='data']")
      |> render()

    assert chart_data =~ "&quot;name&quot;:&quot;Content hits&quot;"
    assert chart_data =~ "&quot;name&quot;:&quot;Content misses&quot;"
    assert chart_data =~ "&quot;borderRadius&quot;:[0,0,2,2]"
    assert chart_data =~ "&quot;borderRadius&quot;:[2,2,0,0]"
    assert has_element?(view, "#translations-table", "Translated")
    assert has_element?(view, "#translations-table", "Content hit")
    assert has_element?(view, "#translations-table", "4 translated, 2 content hits")
    assert has_element?(view, "#translations-table", "7 content hits")
  end

  test "searches, filters, and exposes sortable columns through the URL", %{
    conn: conn,
    project: project,
    user: user
  } do
    path = "/#{user.account.handle}/#{project.handle}"
    {:ok, view, _html} = live(conn, path)

    assert has_element?(view, "#translations-table a[href*='tssort=outcome']")
    assert has_element?(view, "#translations-table a[href*='tssort=translated_content_count']")

    {:ok, searched_view, _html} = live(conn, path <> "?tsq=pricing")
    assert has_element?(searched_view, "#translations-table", "Refresh pricing metadata")
    refute has_element?(searched_view, "#translations-table", "Publish the translated guide")

    {:ok, filtered_view, _html} =
      live(conn, path <> "?filter_outcome_op=%3D%3D&filter_outcome_val=content_hit")

    assert has_element?(filtered_view, "#translations-table", "Content hit")
    refute has_element?(filtered_view, "#translations-table", "Translated")
  end

  test "search treats pattern characters literally", %{
    conn: conn,
    project: project,
    user: user
  } do
    {:ok, _literal} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "literal-percent",
        commit_message: "Publish the guide at 100% coverage",
        status: "completed",
        outcome: "translated"
      })

    {:ok, _similar} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "similar-percent",
        commit_message: "Publish the guide at 100 percent coverage",
        status: "completed",
        outcome: "translated"
      })

    path = "/#{user.account.handle}/#{project.handle}?tsq=100%25"
    {:ok, view, _html} = live(conn, path)

    assert has_element?(view, "#translations-table", "100% coverage")
    refute has_element?(view, "#translations-table", "100 percent coverage")
  end

  test "pluralizes combined translation counts", %{
    conn: conn,
    project: project,
    user: user
  } do
    {:ok, _session} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "singular-counts",
        commit_message: "Translate one item and reuse one item",
        status: "completed",
        outcome: "translated",
        translated_content_count: 1,
        content_hit_count: 1
      })

    {:ok, view, _html} = live(conn, "/#{user.account.handle}/#{project.handle}")

    assert has_element?(view, "#translations-table", "1 translated, 1 content hit")
  end

  test "refreshes when a new translation starts after the overview is open", %{
    conn: conn,
    project: project,
    user: user
  } do
    {:ok, view, _html} = live(conn, "/#{user.account.handle}/#{project.handle}")
    refute has_element?(view, "#translations-table", "Translate newly pushed content")

    {:ok, _session} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "newly-pushed",
        commit_message: "Translate newly pushed content",
        status: "pending"
      })

    assert has_element?(view, "#translations-table", "Translate newly pushed content")
    assert has_element?(view, "#translation-runs-widget", "3")
    assert has_element?(view, "#content-hit-rate-widget", "69.2%")
  end

  test "shows repository destinations for legacy sessions and updates when planning finishes", %{
    conn: conn,
    project: project,
    user: user
  } do
    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        source_language: "en",
        target_languages: nil,
        commit_message: "Translate repository configuration",
        status: "running"
      })

    # The setup wizard has es/fr, but the repository plan has de/ja/pt-BR.
    TranslationSessions.broadcast_session_event(session, %{
      type: "plan_assessed",
      total: 3,
      needs_translation: 2,
      up_to_date: 1,
      queued: [
        %{index: 0, output_path: "de/guide.md", locale: "de"},
        %{index: 1, output_path: "ja/guide.md", locale: "ja"}
      ]
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_skipped",
      index: 2,
      output_path: "pt-BR/guide.md",
      locale: "pt-BR"
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 0,
      output_path: "de/guide.md",
      locale: "de"
    })

    path = ~p"/#{user.account.handle}/#{project.handle}/-/translations"
    {:ok, view, _html} = live(conn, path)
    row = "#translation-session-#{session.id}"
    assert has_element?(view, row, "en -> de, ja, pt-BR")

    {:ok, searched, _html} = live(conn, path <> "?tsq=repository")
    assert has_element?(searched, row, "en -> de, ja, pt-BR")

    {:ok, planned} =
      TranslationSessions.create_session(user.account, project, %{
        source_language: "en",
        status: "running"
      })

    TranslationSessions.broadcast_session_event(planned, %{
      type: "plan",
      total: 2,
      target_languages: ["de", "ko"]
    })

    assert has_element?(view, "#translation-session-#{planned.id}", "en -> de, ko")
    assert TranslationSessions.get_session!(planned.id).target_languages == ["de", "ko"]

    {:ok, reloaded, _html} = live(conn, path)
    assert has_element?(reloaded, "#translation-session-#{planned.id}", "en -> de, ko")
  end
end
