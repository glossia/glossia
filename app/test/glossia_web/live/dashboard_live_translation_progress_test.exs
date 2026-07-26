defmodule GlossiaWeb.DashboardLiveTranslationProgressTest do
  use GlossiaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Glossia.Projects
  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions

  test "running translation items show an active progress indicator", %{conn: conn} do
    user = TestHelpers.create_user("translation-progress@test.com", "translation-progress")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "progress",
        name: "Progress"
      })

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        source_language: "en",
        target_languages: ["de"]
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    assert has_element?(view, ".dash-empty-state", "No events recorded yet.")

    TranslationSessions.broadcast_session_event(session, %{type: "plan", total: 1})

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 0,
      output_path: "app/priv/i18n/de/example.md",
      locale: "de"
    })

    assert has_element?(
             view,
             "#translation-progress [data-status='running'] [data-part='indicator']"
           )

    assert has_element?(
             view,
             "#translation-progress [data-status='running'] [data-part='status']",
             "Translating"
           )

    refute has_element?(view, ".dash-empty-state")
    refute has_element?(view, ".session-event-feed")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_completed",
      index: 0
    })

    refute has_element?(view, "#translation-progress [data-part='indicator']")
    assert has_element?(view, "#translation-progress [data-status='done']", "Done")
  end

  test "a retry clears progress from the previous attempt immediately", %{conn: conn} do
    user =
      TestHelpers.create_user("translation-retry-progress@test.com", "translation-retry-progress")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "retry-progress",
        name: "Retry progress"
      })

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        source_language: "en",
        target_languages: ["es"]
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    TranslationSessions.broadcast_session_event(session, %{type: "plan", total: 1})

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 0,
      output_path: "app/priv/i18n/es/example.md",
      locale: "es"
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_failed",
      index: 0,
      reason: "Previous attempt failed"
    })

    assert has_element?(view, "#translation-progress [data-status='failed']")

    {:ok, _session} = TranslationSessions.update_session_status(session, "running")

    refute has_element?(view, "#translation-progress")
    assert has_element?(view, ".dash-empty-state", "No events recorded yet.")
  end

  test "failed items share an actionable error summary with details on demand", %{conn: conn} do
    user =
      TestHelpers.create_user(
        "translation-failure-summary@test.com",
        "translation-failure-summary"
      )

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "failure-summary",
        name: "Failure summary"
      })

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        source_language: "en",
        target_languages: ["de", "es"]
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    TranslationSessions.broadcast_session_event(session, %{type: "plan", total: 2})

    Enum.each([{0, "de"}, {1, "es"}], fn {index, locale} ->
      TranslationSessions.broadcast_session_event(session, %{
        type: "item_started",
        index: index,
        output_path: "app/priv/i18n/#{locale}/example.md",
        locale: locale
      })

      TranslationSessions.broadcast_session_event(session, %{
        type: "item_failed",
        index: index,
        reason:
          "Model request failed: Credit limit exceeded, please [add credits](https://api.together.ai/settings/billing). Request #{index}."
      })
    end)

    assert has_element?(
             view,
             "#translation-progress [data-part='failure-summary'][data-kind='provider-credit']",
             "Model provider credit limit reached"
           )

    assert has_element?(
             view,
             "#translation-progress [data-part='failure-count']",
             "2 files were affected."
           )

    assert has_element?(
             view,
             "#translation-progress [data-part='failure-action'][href='https://api.together.ai/settings/billing']",
             "Review provider billing"
           )

    assert has_element?(
             view,
             "#translation-progress [data-part='failure-details'] summary",
             "Technical details"
           )

    assert has_element?(
             view,
             "#translation-progress [data-part='failure-details'] pre",
             "Credit limit exceeded"
           )

    refute has_element?(view, "#translation-progress [data-part='reason']")
  end
end
