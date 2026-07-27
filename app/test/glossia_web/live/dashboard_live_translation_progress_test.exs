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

    assert has_element?(view, "#translation-progress-summary-translated", "0/1 translated")
    assert has_element?(view, "#translation-progress-summary-running", "1 in progress")
    assert has_element?(view, "#translation-progress-item-0")

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

  test "provider failures have a shared action and a safe error on every file", %{conn: conn} do
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
        reason: %{
          kind: "provider-credit",
          scope: "session",
          provider: "togetherai",
          status: 402,
          code: "credit_limit",
          request_id: "request_#{index}",
          raw: "provider-secret-#{index}"
        }
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

    refute has_element?(
             view,
             "#translation-progress [data-part='failure-summary'] [data-part='item-diagnostics']"
           )

    Enum.each(0..1, fn index ->
      assert has_element?(
               view,
               "#translation-progress-item-#{index} [data-part='item-failure'][data-kind='provider-credit']",
               "This file could not be translated because the model provider account has no remaining credit."
             )

      assert has_element?(
               view,
               "#translation-progress-item-#{index} [data-part='item-diagnostics'] summary",
               "Diagnostic details"
             )

      assert has_element?(
               view,
               "#translation-progress-item-#{index} [data-part='item-diagnostics'][id][phx-mounted]"
             )

      assert has_element?(
               view,
               "#translation-progress-item-#{index} [data-part='item-diagnostics']",
               "request_#{index}"
             )
    end)

    html = render(view)
    refute html =~ "provider-secret"
    refute html =~ "Technical details"
  end

  test "file-specific validation failures stay with their file", %{conn: conn} do
    user =
      TestHelpers.create_user(
        "translation-validation-failure@test.com",
        "translation-validation-failure"
      )

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "validation-failure",
        name: "Validation failure"
      })

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        source_language: "en",
        target_languages: ["fr"]
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    TranslationSessions.broadcast_session_event(session, %{type: "plan", total: 1})

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 0,
      output_path: "app/priv/i18n/fr/example.md",
      locale: "fr"
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "text", text: "Incomplete translated output"}
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_failed",
      index: 0,
      reason: %{
        kind: "validation-command",
        scope: "item",
        raw: "TOKEN=repository-secret"
      }
    })

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='item-failure'][data-kind='validation-command']",
             "The validation command rejected the translated output for this file."
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='partial-output'] summary",
             "Show incomplete output"
           )

    refute has_element?(view, "#translation-progress [data-part='failure-summary']")
    refute render(view) =~ "repository-secret"
  end

  test "a session must belong to the account and project in the route", %{conn: conn} do
    first_user =
      TestHelpers.create_user("translation-route-first@test.com", "translation-route-first")

    second_user =
      TestHelpers.create_user("translation-route-second@test.com", "translation-route-second")

    {:ok, first_project} =
      Projects.create_project(first_user.account, %{
        handle: "first-project",
        name: "First project"
      })

    {:ok, second_project} =
      Projects.create_project(second_user.account, %{
        handle: "second-project",
        name: "Second project"
      })

    {:ok, second_session} =
      TranslationSessions.create_session(second_user.account, second_project, %{
        status: "running",
        source_language: "en",
        target_languages: ["de"]
      })

    conn = init_test_session(conn, %{user_id: first_user.id})
    path = "/#{first_user.account.handle}/#{first_project.handle}/-/sessions/#{second_session.id}"

    assert_raise Ecto.NoResultsError, fn -> live(conn, path) end
  end
end
