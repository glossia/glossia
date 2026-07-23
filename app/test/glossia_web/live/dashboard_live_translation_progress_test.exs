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

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_completed",
      index: 0
    })

    refute has_element?(view, "#translation-progress [data-part='indicator']")
    assert has_element?(view, "#translation-progress [data-status='done']", "Done")
  end
end
