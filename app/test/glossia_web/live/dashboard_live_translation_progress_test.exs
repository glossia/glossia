defmodule GlossiaWeb.DashboardLiveTranslationProgressTest do
  use GlossiaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Glossia.Projects
  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions

  test "a running translation session can be cancelled" do
    user = TestHelpers.create_user("cancel-translation@test.com", "cancel-translation")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "cancel-progress",
        name: "Cancel progress",
        github_repo_full_name: "example/cancel-progress"
      })

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        commit_sha: "0123456789abcdef0123456789abcdef01234567",
        source_language: "en",
        target_languages: ["de"]
      })

    assert {:ok, cancelled_session} = TranslationSessions.cancel_session(session)
    assert cancelled_session.status == "cancelled"

    assert TranslationSessions.get_session!(session.id).status == "cancelled"
  end

  # A reasoning model can spend a whole minute thinking before it writes the
  # first character of a translation, which used to leave the page looking dead.
  test "a running session shows the model's reasoning and a header spinner", %{conn: conn} do
    user = TestHelpers.create_user("translation-reasoning@test.com", "translation-reasoning")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "reasoning",
        name: "Reasoning",
        github_repo_full_name: "example/reasoning"
      })

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        commit_sha: "0123456789abcdef0123456789abcdef01234567",
        source_language: "en",
        target_languages: ["de"]
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    assert has_element?(view, "#translation-session [data-part='status'] [data-part='spinner']")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 0,
      total: 1,
      output_path: "app/priv/i18n/de/example.md",
      locale: "de"
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "segment_start", index: 1, count: 3, kind: "frontmatter"}
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "thinking", text: "The title is a metaphor, so:\n\n* "}
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "thinking", text: "it should **not** be translated literally."}
    })

    # The model writes markdown, so it is rendered rather than shown as source.
    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='live-output'][data-kind='reasoning'] [data-part='prose'] li strong",
             "not"
           )

    refute render(view) =~ "**not**"

    # The two boundaries this change stopped clearing reasoning on. Reinstating
    # either clear drops it here and fails every assertion below.
    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "segment_output", text: "%{title: \"Der Titel\"}"}
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "segment_start", index: 2, count: 3, kind: "content"}
    })

    # Its translation has arrived, so it leaves the active box for a completed
    # segment disclosure. The active area now reflects the next segment.
    refute has_element?(
             view,
             "#translation-progress-item-0 [data-part='live-output']:not([data-kind='reasoning']) [data-part='stream']",
             "Der Titel"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='completed-segment'] summary",
             "Front matter"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='completed-segment'] [data-part='stream']",
             "Der Titel"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='live-output'][data-kind='reasoning'] [data-part='prose'] li",
             "it should not be translated literally."
           )

    refute has_element?(view, "#translation-progress-item-0-reasoning")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_completed",
      index: 0,
      file_ref: "glossia/translate-0123456789ab"
    })

    assert has_element?(
             view,
             "#translation-progress-item-0-reasoning [data-part='prose']",
             "The title is a metaphor"
           )

    # A fresh attempt is the one thing that does discard it, along with the
    # markup it was rendered into.
    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "attempt_start", attempt: 2}
    })

    refute has_element?(view, "#translation-progress-item-0-reasoning")

    {:ok, _session} = TranslationSessions.update_session_status(session, "completed")

    refute has_element?(view, "#translation-session [data-part='spinner']")
  end

  test "a model that stops at its output limit is reported as such", %{conn: conn} do
    user = TestHelpers.create_user("translation-budget@test.com", "translation-budget")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "budget",
        name: "Budget",
        github_repo_full_name: "example/budget"
      })

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        commit_sha: "0123456789abcdef0123456789abcdef01234567",
        source_language: "en",
        target_languages: ["de"]
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 0,
      total: 1,
      output_path: "app/priv/i18n/de/example.md",
      locale: "de"
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_failed",
      index: 0,
      reason:
        Glossia.Translations.Failure.from(
          {:validation_failed, "translated output was empty for non-empty frontmatter"},
          "togetherai"
        )
    })

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='item-failure'][data-kind='validation-empty-output']",
             "The model returned empty output"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='item-failure-description']",
             "can spend its whole output budget thinking and return nothing"
           )
  end

  # Reasoning is the one place in the dashboard that renders text a model wrote
  # into the page. Raw markup must not survive as markup, and a link or image
  # URL the model chooses must not be able to carry a scheme that executes.
  test "renders model reasoning without letting its markup or URLs go live", %{conn: conn} do
    user = TestHelpers.create_user("translation-sanitize@test.com", "translation-sanitize")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "sanitize",
        name: "Sanitize",
        github_repo_full_name: "example/sanitize"
      })

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        commit_sha: "0123456789abcdef0123456789abcdef01234567",
        source_language: "en",
        target_languages: ["de"]
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 0,
      total: 1,
      output_path: "app/priv/i18n/de/example.md",
      locale: "de"
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{
        type: "thinking",
        text: """
        Weighing <script>alert(1)</script> and <img src=x onerror="alert(2)"> here.

        Also [a link](javascript:alert(3)) and ![an image](data:text/html;base64,PHNjcmlwdD4=).
        """
      }
    })

    reasoning =
      view
      |> element("#translation-progress-item-0 [data-part='prose']")
      |> render()

    assert reasoning =~ "Weighing"
    assert reasoning =~ "a link"

    # Raw markup does not survive as markup, escaped or otherwise.
    refute reasoning =~ "<script"
    refute reasoning =~ "&lt;script"
    refute reasoning =~ "onerror"

    # A markdown link or image cannot carry a scheme that executes. Anything
    # other than an empty href here means a URL the model chose reached the
    # browser intact.
    refute reasoning =~ "javascript:"
    refute reasoning =~ "data:text/html"
    assert reasoning =~ ~s(href="")
  end

  # A progress event re-renders every item several times a second, and each patch
  # reset an output the viewer had unfolded. The fix is client-side, so what can
  # be asserted from here is that the instruction is on the element and its id is
  # stable; whether the browser honours it is LiveView's own contract.
  test "marks the output disclosures so a patch cannot collapse them", %{conn: conn} do
    user = TestHelpers.create_user("translation-details@test.com", "translation-details")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "details",
        name: "Details",
        github_repo_full_name: "example/details"
      })

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        commit_sha: "0123456789abcdef0123456789abcdef01234567",
        source_language: "en",
        target_languages: ["de"]
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 0,
      total: 1,
      output_path: "app/priv/i18n/de/example.md",
      locale: "de"
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "translation_output", text: "Der Titel"}
    })

    TranslationSessions.broadcast_session_event(session, %{type: "item_completed", index: 0})

    rendered =
      view
      |> element("#translation-progress-item-0-completed-output")
      |> render()

    assert rendered =~ "phx-mounted"
    assert rendered =~ "ignore_attrs"

    # The id is derived from the planned item index, which is also what
    # `Progress.items/1` sorts by, so it survives later items arriving.
    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 1,
      total: 2,
      output_path: "app/priv/i18n/es/example.md",
      locale: "es"
    })

    assert has_element?(view, "#translation-progress-item-0-completed-output")
  end

  test "restores cached progress when the viewer reconnects", %{conn: conn} do
    user = TestHelpers.create_user("translation-reconnect@test.com", "translation-reconnect")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "reconnect-progress",
        name: "Reconnect progress",
        github_repo_full_name: "example/reconnect-progress"
      })

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        commit_sha: "0123456789abcdef0123456789abcdef01234567",
        source_language: "en",
        target_languages: ["de"]
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, _view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    TranslationSessions.broadcast_session_event(session, %{type: "plan", total: 1})

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 0,
      total: 1,
      output_path: "app/priv/i18n/de/example.md",
      locale: "de"
    })

    {:ok, reconnected_view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    assert has_element?(reconnected_view, "#translation-progress-item-0")

    assert has_element?(
             reconnected_view,
             "#translation-progress-item-0 [data-part='path']",
             "app/priv/i18n/de/example.md"
           )
  end

  test "running translation items show an active progress indicator", %{conn: conn} do
    user = TestHelpers.create_user("translation-progress@test.com", "translation-progress")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "progress",
        name: "Progress",
        github_repo_full_name: "example/progress"
      })

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        commit_sha: "0123456789abcdef0123456789abcdef01234567",
        source_language: "en",
        target_languages: ["de"]
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    assert has_element?(view, ".dash-empty-state", "No events recorded yet.")

    TranslationSessions.broadcast_session_event(session, %{type: "plan", total: 1})

    assert has_element?(
             view,
             "#translation-progress-summary-checking",
             "Checking 0 of 1 file for updates"
           )

    refute has_element?(view, "#translation-progress-summary-running")

    TranslationSessions.broadcast_session_event(session, %{
      type: "plan_assessed",
      total: 1,
      needs_translation: 1,
      up_to_date: 0
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 0,
      total: 1,
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
    refute has_element?(view, "#translation-progress-summary-checking")
    assert has_element?(view, "#translation-progress-summary-running", "1 in progress")
    assert has_element?(view, "#translation-progress-item-0")

    refute has_element?(view, "#translation-progress-item-0 a[data-part='path']")

    assert has_element?(
             view,
             "#translation-progress-item-0 span[data-part='path']",
             "app/priv/i18n/de/example.md"
           )

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "attempt_start", attempt: 1}
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "segment_start", index: 1, count: 2, kind: "frontmatter"}
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "turn_start"}
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "text", text: "translated front matter"}
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "segment_output", text: "translated front matter"}
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "segment_start", index: 2, count: 2, kind: "content"}
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "turn_start"}
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "text", text: ""}
    })

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='progress-meta']",
             "Segment 2 of 2"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='progress-meta']",
             "2 model calls"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='stream']",
             "translated front matter"
           )

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "text", text: "translated body"}
    })

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='stream']",
             "translated front matter"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='stream']",
             "translated body"
           )

    refute has_element?(view, ".dash-empty-state")
    refute has_element?(view, ".session-event-feed")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_completed",
      index: 0,
      file_ref: "glossia/translate-0123456789ab"
    })

    refute has_element?(view, "#translation-progress [data-part='indicator']")
    assert has_element?(view, "#translation-progress [data-status='done']", "Done")

    assert has_element?(
             view,
             "#translation-progress-item-0 a[data-part='path'][href='https://github.com/example/progress/blob/glossia/translate-0123456789ab/app/priv/i18n/de/example.md'][target='_blank']",
             "app/priv/i18n/de/example.md"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='completed-output'] summary",
             "Show translated output"
           )

    {:ok, _session} =
      TranslationSessions.update_session_publication(session, %{
        publication_branch: "glossia/translate-0123456789ab",
        publication_commit_sha: "translated-commit",
        pull_request_url: "https://github.com/example/progress/pull/42"
      })

    assert has_element?(
             view,
             "#translation-session [data-part='metadata'] a[href='https://github.com/example/progress/pull/42']",
             "Open pull request"
           )
  end

  test "the in-progress summary stays visible while the next file is queued", %{conn: conn} do
    user =
      TestHelpers.create_user(
        "translation-progress-handoff@test.com",
        "translation-progress-handoff"
      )

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "progress-handoff",
        name: "Progress handoff"
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

    TranslationSessions.broadcast_session_event(session, %{type: "plan", total: 2})

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 0,
      output_path: "app/priv/i18n/de/first.md",
      locale: "de"
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_failed",
      index: 0,
      reason: "First file failed"
    })

    assert has_element?(view, "#translation-progress-summary-running", "1 in progress")

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='status-icon'] svg.icon-tabler-alert-circle"
           )

    refute has_element?(view, "#translation-progress-item-0 [data-part='item-failure-icon']")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 1,
      output_path: "app/priv/i18n/de/second.md",
      locale: "de"
    })

    assert has_element?(view, "#translation-progress-summary-running", "1 in progress")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_failed",
      index: 1,
      reason: "Second file failed"
    })

    refute has_element?(view, "#translation-progress-summary-running")
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

  test "a generic provider error joins the provider's single specific failure group", %{
    conn: conn
  } do
    user =
      TestHelpers.create_user(
        "translation-provider-failure-group@test.com",
        "provider-failure-group"
      )

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "provider-failure-group",
        name: "Provider failure group"
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

    TranslationSessions.broadcast_session_event(session, %{type: "plan", total: 2})

    Enum.each(
      [{0, "provider-credit"}, {1, "provider-error"}],
      fn {index, kind} ->
        TranslationSessions.broadcast_session_event(session, %{
          type: "item_started",
          index: index,
          output_path: "app/priv/i18n/de/example-#{index}.md",
          locale: "de"
        })

        TranslationSessions.broadcast_session_event(session, %{
          type: "item_failed",
          index: index,
          reason: %{
            kind: kind,
            scope: "session",
            provider: "togetherai"
          }
        })
      end
    )

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

    refute has_element?(
             view,
             "#translation-progress [data-part='failure-summary'][data-kind='provider-error']"
           )

    failure_summaries =
      view
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("#translation-progress [data-part='failure-summary']")

    assert Enum.count(failure_summaries) == 1
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

  test "empty model output explains that no changes were published", %{conn: conn} do
    user =
      TestHelpers.create_user("translation-empty-output@test.com", "translation-empty-output")

    {:ok, project} =
      Projects.create_project(user.account, %{handle: "empty-output", name: "Empty output"})

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
      type: "item_failed",
      index: 0,
      output_path: "app/priv/i18n/de/docs/how-to/retry-project-setup.md",
      locale: "de",
      reason: %{kind: "validation-empty-output", scope: "item"}
    })

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='item-failure'][data-kind='validation-empty-output']",
             "Glossia rejected this empty translation and did not publish any changes."
           )
  end

  test "a repository with nothing to translate says so once", %{conn: conn} do
    user = TestHelpers.create_user("translation-up-to-date@test.com", "translation-up-to-date")

    {:ok, project} =
      Projects.create_project(user.account, %{handle: "up-to-date", name: "Up to date"})

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        source_language: "en",
        target_languages: ["de"]
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    TranslationSessions.broadcast_session_event(session, %{type: "plan", total: 231})

    TranslationSessions.broadcast_session_event(session, %{
      type: "plan_assessed",
      total: 231,
      needs_translation: 0,
      up_to_date: 231
    })

    assert has_element?(
             view,
             "#translation-progress-summary-up-to-date",
             "No translations needed"
           )

    # "No translations needed" and "231 up to date" say the same thing.
    refute has_element?(view, "#translation-progress-summary-skipped")
    refute has_element?(view, "#translation-progress-summary-running")
    refute has_element?(view, "#translation-progress-summary-checking")
  end

  test "a viewer who joins mid-run sees translation progress, not a stuck check", %{conn: conn} do
    user = TestHelpers.create_user("translation-late-join@test.com", "translation-late-join")

    {:ok, project} =
      Projects.create_project(user.account, %{handle: "late-join", name: "Late join"})

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        source_language: "en",
        target_languages: ["de"]
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    # Progress is not replayed on mount, so a viewer arriving after the plan was
    # assessed never receives `plan_assessed`. Neither does a session driven by
    # a runner from an earlier release during a rolling deploy.
    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 0,
      total: 4,
      output_path: "app/priv/i18n/de/first.md",
      locale: "de"
    })

    assert has_element?(view, "#translation-progress-summary-translated", "0/4 translated")
    refute has_element?(view, "#translation-progress-summary-checking")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_completed",
      index: 0,
      output_path: "app/priv/i18n/de/first.md"
    })

    assert has_element?(view, "#translation-progress-summary-translated", "1/4 translated")
    assert has_element?(view, "#translation-progress-summary-running", "1 in progress")
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
