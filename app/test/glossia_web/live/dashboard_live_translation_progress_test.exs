defmodule GlossiaWeb.DashboardLiveTranslationProgressTest do
  use GlossiaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Glossia.Projects
  alias Glossia.Repo
  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions
  alias Glossia.Translations.DependencyDiff

  test "large plans paginate while preserving live progress and session-wide totals", %{
    conn: conn
  } do
    user = TestHelpers.create_user("large-plan@test.com", "large-plan")
    {:ok, project} = Projects.create_project(user.account, %{handle: "docs", name: "Docs"})

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{status: "running"})

    TranslationSessions.broadcast_session_event(session, %{
      type: "plan_assessed",
      total: 123,
      needs_translation: 123,
      up_to_date: 0,
      queued:
        for index <- 0..122 do
          %{index: index, output_path: "es/guide-#{index}.md", locale: "es"}
        end
    })

    conn = init_test_session(conn, %{user_id: user.id})
    path = ~p"/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}"
    {:ok, view, html} = live(conn, path)

    assert Enum.count(
             LazyHTML.query(LazyHTML.from_document(html), "#translation-progress-items-body > tr")
           ) ==
             50

    assert has_element?(view, "#translation-progress-item-0", "Queued")
    assert has_element?(view, "#translation-progress-item-49", "Queued")
    refute has_element?(view, "#translation-progress-item-50")
    assert has_element?(view, "#translation-progress-summary-translated", "0/123 translated")

    view
    |> element("#translation-progress-pagination [data-part='page-button']", "3")
    |> render_click()

    assert_patch(view, path <> "?files_page=3")
    assert has_element?(view, "#translation-progress-item-100", "Queued")
    assert has_element?(view, "#translation-progress-item-122", "Queued")
    refute has_element?(view, "#translation-progress-item-99")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_started",
      index: 122,
      output_path: "es/guide-122.md",
      locale: "es"
    })

    # A running file moves ahead of queued files, so it now belongs to page one.
    refute has_element?(view, "#translation-progress-item-122")
    assert has_element?(view, "#translation-progress-summary-running", "1 in progress")

    send(view.pid, :refresh_translation_session)
    render(view)

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 122,
      event: %{type: "text", text: "Salida en curso"}
    })

    render_patch(view, path)
    assert has_element?(view, "#translation-progress-item-122", "Translating")
    assert has_element?(view, "#translation-progress-item-122-expanded", "Salida en curso")

    send(view.pid, :refresh_translation_session)
    assert has_element?(view, "#translation-progress-item-122-expanded", "Salida en curso")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_completed",
      index: 122,
      output_preview: "Salida terminada"
    })

    assert has_element?(view, "#translation-progress-item-122", "Done")
    assert has_element?(view, "#translation-progress-summary-translated", "1/123 translated")

    # Simulate a lost milestone broadcast followed by a newer live event.
    missed_seq = TranslationSessions.max_progress_seq(session.id) + 1

    %Glossia.TranslationSessions.ProgressEvent{}
    |> Glossia.TranslationSessions.ProgressEvent.changeset(%{
      session_id: session.id,
      seq: missed_seq,
      payload: %{type: "item_completed", seq: missed_seq, index: 0}
    })
    |> Repo.insert!()

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      seq: missed_seq + 1,
      index: 122,
      event: %{type: "turn_start"}
    })

    send(view.pid, :refresh_translation_session)
    assert has_element?(view, "#translation-progress-item-0", "Done")
    assert has_element?(view, "#translation-progress-summary-translated", "2/123 translated")

    # Concurrent producers can commit an older sequence after the next poll.
    late_seq = TranslationSessions.max_progress_seq(session.id) + 2

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_completed",
      seq: late_seq + 1,
      index: 2
    })

    send(view.pid, :refresh_translation_session)
    assert has_element?(view, "#translation-progress-summary-translated", "3/123 translated")

    %Glossia.TranslationSessions.ProgressEvent{}
    |> Glossia.TranslationSessions.ProgressEvent.changeset(%{
      session_id: session.id,
      seq: late_seq,
      payload: %{type: "item_completed", seq: late_seq, index: 1}
    })
    |> Repo.insert!()

    send(view.pid, :refresh_translation_session)
    assert has_element?(view, "#translation-progress-item-1", "Done")
    assert has_element?(view, "#translation-progress-summary-translated", "4/123 translated")

    # Paging a finished session must reconcile before cancelling its last poll.
    %Glossia.TranslationSessions.ProgressEvent{}
    |> Glossia.TranslationSessions.ProgressEvent.changeset(%{
      session_id: session.id,
      seq: late_seq + 2,
      payload: %{type: "item_completed", seq: late_seq + 2, index: 3}
    })
    |> Repo.insert!()

    session |> Ecto.Changeset.change(status: "completed") |> Repo.update!()
    send(view.pid, {:translation_session_status, "completed"})
    render_patch(view, path <> "?files_page=2")
    assert has_element?(view, "#translation-progress-summary-translated", "5/123 translated")

    render_patch(view, path <> "?files_page=999")
    assert has_element?(view, "#translation-progress-pagination [data-selected]", "3")

    TranslationSessions.broadcast_session_event(session, %{
      type: "run_started",
      seq: late_seq + 3
    })

    assert has_element?(view, "#translation-progress-items .noora-table-empty-state")
    refute has_element?(view, "#translation-progress-pagination")
    refute has_element?(view, "#translation-progress-item-122")
  end

  test "publication broadcasts and polling refresh file links without losing live output", %{
    conn: conn
  } do
    user = TestHelpers.create_user("published-links@test.com", "published-links")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "docs",
        name: "Docs",
        github_repo_full_name: "example/docs"
      })

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{status: "running"})

    for index <- 0..1 do
      TranslationSessions.broadcast_session_event(session, %{
        type: "item_started",
        index: index,
        output_path: "es/guide-#{index}.md",
        locale: "es"
      })
    end

    TranslationSessions.broadcast_session_event(session, %{type: "item_completed", index: 0})

    conn = init_test_session(conn, %{user_id: user.id})
    {:ok, view, _html} = live(conn, ~p"/#{user.account.handle}/docs/-/sessions/#{session.id}")
    refute has_element?(view, "#translation-progress-item-0 a[data-part='path']")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 1,
      event: %{type: "text", text: "Salida en curso"}
    })

    {:ok, session} =
      TranslationSessions.update_session_publication(session, %{
        publication_commit_sha: "first-publication"
      })

    assert has_element?(
             view,
             "#translation-progress-item-0 a[href='https://github.com/example/docs/blob/first-publication/es/guide-0.md']"
           )

    assert has_element?(view, "#translation-progress-item-1-expanded", "Salida en curso")

    # Recover a publication whose broadcast was missed, with no new file events.
    session
    |> Ecto.Changeset.change(publication_commit_sha: "next-publication")
    |> Repo.update!()

    send(view.pid, :refresh_translation_session)

    assert has_element?(
             view,
             "#translation-progress-item-0 a[href='https://github.com/example/docs/blob/next-publication/es/guide-0.md']"
           )

    assert has_element?(view, "#translation-progress-item-1-expanded", "Salida en curso")

    # A status refetch must not consume the changed SHA without refreshing links.
    session
    |> Ecto.Changeset.change(
      status: "awaiting_input",
      publication_commit_sha: "last-publication"
    )
    |> Repo.update!()

    send(view.pid, {:translation_session_status, "awaiting_input"})
    send(view.pid, :refresh_translation_session)

    assert has_element?(
             view,
             "#translation-progress-item-0 a[href='https://github.com/example/docs/blob/last-publication/es/guide-0.md']"
           )

    assert has_element?(view, "#translation-progress-item-1-expanded", "Salida en curso")
  end

  test "waiting files show linguistic input rather than an active translation", %{conn: conn} do
    user = TestHelpers.create_user("waiting-linguist@test.com", "waiting-linguist")

    {:ok, project} =
      Projects.create_project(user.account, %{handle: "release", name: "Release docs"})

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "awaiting_input",
        commit_message: "Clarify release-branch terminology",
        source_language: "en",
        target_languages: ["es"]
      })

    Enum.each(
      [
        %{type: "plan", seq: 1, total: 2},
        %{type: "plan_assessed", seq: 2, total: 2, needs_translation: 2, up_to_date: 0},
        %{
          type: "item_awaiting_input",
          seq: 3,
          index: 0,
          output_path: "es/releases.txt",
          locale: "es"
        },
        %{type: "item_started", seq: 4, index: 1, output_path: "es/start.txt", locale: "es"},
        %{type: "item_completed", seq: 5, index: 1, output_path: "es/start.txt", locale: "es"}
      ],
      &TranslationSessions.broadcast_session_event(session, &1)
    )

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    assert has_element?(view, "#translation-progress-item-0", "Needs linguistic input")
    assert has_element?(view, "#translation-progress-item-1", "Done")
    refute has_element?(view, "#translation-progress-summary-running")
    assert has_element?(view, "#cancel-translation-session")
  end

  test "shows persisted per-file translation reasons, including completed files", %{conn: conn} do
    user = TestHelpers.create_user("translation-reasons@test.com", "translation-reasons")
    {:ok, project} = Projects.create_project(user.account, %{handle: "reasons", name: "Reasons"})

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{status: "completed"})

    Enum.each(
      [
        %{
          type: "plan_assessed",
          seq: 1,
          total: 2,
          needs_translation: 2,
          up_to_date: 0,
          queued: [
            %{
              index: 0,
              output_path: "es/guide.md",
              locale: "es",
              translation_reasons: ["model_changed", "validation_changed"],
              translation_diff: %{
                "version" => 1,
                "baseline" => "recorded",
                "source_commit_sha" => "abc123",
                "tree" => %{
                  "kind" => "translation_config",
                  "label" => "generation",
                  "change" => "changed",
                  "aggregate_only" => false,
                  "fields" => [
                    %{
                      "field" => "model",
                      "before" => "old-writer",
                      "after" => "new-writer",
                      "before_present" => true,
                      "after_present" => true,
                      "change" => "changed",
                      "fingerprint" => false
                    }
                  ],
                  "children" => []
                }
              }
            }
          ]
        },
        %{type: "item_started", seq: 2, index: 0, output_path: "es/guide.md", locale: "es"},
        %{type: "item_completed", seq: 3, index: 0},
        %{type: "item_started", seq: 4, index: 1, output_path: "es/legacy.md", locale: "es"}
      ],
      &TranslationSessions.broadcast_session_event(session, &1)
    )

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    assert has_element?(view, "#translation-progress-items", "Why translating")
    assert has_element?(view, "#translation-progress-item-0", "Model changed")
    assert has_element?(view, "#translation-progress-item-0", "Validation rules changed")
    assert has_element?(view, "#translation-progress-item-1", "Not recorded")

    assert has_element?(
             view,
             "#translation-progress-item-0-expanded [data-part='input-summary']",
             "Why translation was needed"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0-expanded [data-part='change-summary']",
             "The translation model changed. The validation rules changed."
           )

    refute html =~ "old-writer"
    refute html =~ "new-writer"
    refute html =~ "abc123"
    refute has_element?(view, "#translation-progress-item-1-expanded [data-part='input-summary']")
  end

  test "summaries distinguish known changes from missing or incomplete history", %{conn: conn} do
    user = TestHelpers.create_user("change-summary@test.com", "change-summary")
    {:ok, project} = Projects.create_project(user.account, %{handle: "summary", name: "Summary"})

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{status: "running"})

    entry = %{
      "term_hash" => "term",
      "translation_hash" => "translation",
      "definition_hash" => "definition",
      "case_sensitive" => false
    }

    previous =
      Map.new(~w(removed renamed translation definition case unchanged), &{"entry:#{&1}", entry})

    current =
      previous
      |> Map.delete("entry:removed")
      |> Map.put("entry:added-1", entry)
      |> Map.put("entry:added-2", entry)
      |> put_in(["entry:renamed", "term_hash"], "new-term")
      |> put_in(["entry:translation", "translation_hash"], "new-translation")
      |> put_in(["entry:definition", "translation_hash"], "another-translation")
      |> put_in(["entry:definition", "definition_hash"], "new-definition")
      |> put_in(["entry:case", "case_sensitive"], true)

    glossary = %{
      "kind" => "context",
      "label" => "terminology",
      "metadata" => %{"content_hash" => "previous"},
      "details" => %{"content_hash" => previous},
      "children" => []
    }

    changed_glossary =
      glossary
      |> put_in(["metadata", "content_hash"], "current")
      |> put_in(["details", "content_hash"], current)

    # The same field names elsewhere must not count as glossary edits.
    unrelated = %{glossary | "label" => "project"}
    changed_unrelated = %{changed_glossary | "label" => "project"}

    before = %{
      "kind" => "translation_input",
      "label" => "en/guide.md",
      "metadata" => %{},
      "children" => [glossary, unrelated]
    }

    after_value = %{before | "children" => [changed_glossary, changed_unrelated]}
    tree = DependencyDiff.diff(before, after_value)

    partial_history =
      update_in(glossary, ["details", "content_hash"], fn entries ->
        Map.new(entries, fn {id, fields} -> {id, Map.delete(fields, "translation_hash")} end)
      end)

    cases = [
      {
        ["source_changed"],
        nil,
        "The source text changed since the last accepted translation."
      },
      {
        ["glossary_changed", "voice_changed", "glossary_changed"],
        %{"baseline" => "recorded"},
        "The glossary used for this file changed; term-level details are unavailable for this comparison. The writing style guidance changed."
      },
      {
        ["glossary_changed"],
        %{"baseline" => "recorded", "tree" => tree},
        "The glossary used for this file changed: 2 terms added, 1 term removed, 1 term renamed, 2 translations updated, 1 definition updated, case sensitivity changed for 1 term."
      },
      {
        ["glossary_changed"],
        %{"baseline" => "missing_lockfile", "tree" => tree},
        "The glossary used for this file changed; term-level details are unavailable for this comparison."
      },
      {
        ["glossary_changed"],
        %{
          "baseline" => "recorded",
          "tree" => DependencyDiff.diff(Map.delete(glossary, "details"), changed_glossary)
        },
        "The glossary used for this file changed; term-level details are unavailable for this comparison."
      },
      {
        ["glossary_changed"],
        %{
          "baseline" => "recorded",
          "tree" =>
            DependencyDiff.diff(
              partial_history,
              put_in(glossary, ["metadata", "content_hash"], "current")
            )
        },
        "The glossary used for this file changed; term-level details are unavailable for this comparison."
      },
      {
        ["lockfile_missing", "output_missing"],
        %{"baseline" => "missing_lockfile"},
        "No usable previous translation record was found. The translated file is missing or empty."
      },
      {
        [],
        %{"baseline" => "missing_lockfile"},
        "No usable previous translation record was found."
      },
      {
        ["translation_inputs_changed"],
        %{"baseline" => "legacy_lockfile"},
        "Translation inputs changed, but the previous record does not identify which ones."
      },
      {
        [],
        %{"baseline" => "legacy_lockfile"},
        "Translation inputs changed, but the previous record does not identify which ones."
      }
    ]

    queued =
      cases
      |> Enum.with_index()
      |> Enum.map(fn {{reasons, diff, _summary}, index} ->
        %{
          index: index,
          output_path: "es/guide-#{index}.md",
          locale: "es",
          translation_reasons: reasons,
          translation_diff: diff
        }
      end)

    TranslationSessions.broadcast_session_event(session, %{
      type: "plan_assessed",
      seq: 1,
      total: length(cases),
      needs_translation: length(cases),
      up_to_date: 0,
      queued: queued
    })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    for {{_reasons, _diff, summary}, index} <- Enum.with_index(cases) do
      text =
        view
        |> element(
          "#translation-progress-item-#{index}-input-summary [data-part='change-summary']"
        )
        |> render()
        |> LazyHTML.from_fragment()
        |> LazyHTML.text()
        |> String.trim()

      assert text == summary
    end

    refute html =~ "fingerprint"
    refute has_element?(view, "[data-part='dependency-node']")
  end

  test "public and restricted readers never see persisted private glossary identifiers", %{
    conn: conn
  } do
    owner = TestHelpers.create_user("diff-owner@example.test", "diff-owner")
    member = TestHelpers.create_user("diff-member@example.test", "diff-member")

    {:ok, %{organization: organization, account: account}} =
      Glossia.Organizations.create_organization(owner, %{handle: "private-diff"})

    {:ok, membership} = Glossia.Organizations.add_member(organization, member)
    membership |> Ecto.Changeset.change(scopes: ["project:read"]) |> Repo.update!()
    account = account |> Ecto.Changeset.change(visibility: "public") |> Repo.update!()
    {:ok, project} = Projects.create_project(account, %{handle: "docs", name: "Docs"})
    {:ok, session} = TranslationSessions.create_session(account, project, %{status: "completed"})

    entry = %{
      "kind" => "detail",
      "label" => "account:SECRET-ACQUISITION",
      "change" => "changed",
      "aggregate_only" => false,
      "children" => [],
      "fields" => [
        %{
          "field" => "translation_hash",
          "before" => "old-hash",
          "after" => "new-hash",
          "change" => "changed",
          "fingerprint" => true,
          "before_present" => true,
          "after_present" => true
        }
      ]
    }

    group = %{entry | "label" => "content_hash", "fields" => [], "children" => [entry]}

    tree = %{
      entry
      | "kind" => "context",
        "label" => "terminology",
        "fields" => [],
        "children" => [group]
    }

    TranslationSessions.broadcast_session_event(session, %{
      type: "plan_assessed",
      seq: 1,
      total: 1,
      needs_translation: 1,
      up_to_date: 0,
      queued: [
        %{
          index: 0,
          output_path: "es/guide.md",
          locale: "es",
          translation_reasons: ["glossary_changed"],
          translation_diff: %{
            "version" => 1,
            "baseline" => "recorded",
            "tree" => tree
          }
        }
      ]
    })

    for viewer <- [nil, member, owner] do
      viewer_conn = if viewer, do: init_test_session(conn, %{user_id: viewer.id}), else: conn

      {:ok, view, html} =
        live(viewer_conn, ~p"/#{account.handle}/#{project.handle}/-/sessions/#{session.id}")

      refute html =~ "SECRET-ACQUISITION"
      refute html =~ "old-hash"
      refute html =~ "new-hash"

      assert has_element?(
               view,
               "[data-part=change-summary]",
               "The glossary used for this file changed: 1 translation updated."
             )
    end
  end

  test "shows the executing engine digest separately from the repository commit", %{conn: conn} do
    user = TestHelpers.create_user("engine-provenance@test.com", "engine-provenance")

    {:ok, project} =
      Projects.create_project(user.account, %{handle: "engine", name: "Engine"})

    image = "ghcr.io/glossia/glossia@sha256:" <> String.duplicate("b", 64)

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "completed",
        commit_sha: String.duplicate("a", 40),
        engine_image: image
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    assert has_element?(view, "#translation-engine-image", "sha256:bbbbbbbbbbbb")
    assert html =~ image
    assert html =~ "aaaaaaa"
    assert html =~ "Translation engine"
  end

  test "sessions without progress use Noora empty states inside both cards", %{conn: conn} do
    user = TestHelpers.create_user("translation-empty-state@test.com", "translation-empty-state")

    {:ok, project} =
      Projects.create_project(user.account, %{handle: "empty-state", name: "Empty state"})

    conn = init_test_session(conn, %{user_id: user.id})

    for status <- ["pending", "running", "completed", "failed", "cancelled"] do
      {:ok, session} =
        TranslationSessions.create_session(user.account, project, %{status: status})

      {:ok, view, _html} =
        live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

      files_empty = "[data-part='translation-files-card'] .noora-table-empty-state"
      activity_empty = "[data-part='session-events-section'].noora-table .noora-table-empty-state"

      assert has_element?(view, files_empty <> " [data-part='icon'] svg")
      assert has_element?(view, files_empty <> " [data-part='title']", "No translated files")
      assert has_element?(view, activity_empty <> " [data-part='icon'] svg")
      assert has_element?(view, activity_empty <> " [data-part='title']", "No activity recorded")

      if status in ["pending", "running"] do
        assert has_element?(view, files_empty, "Files will appear here when translation starts.")

        assert has_element?(
                 view,
                 activity_empty,
                 "Session activity will appear here as the translation runs."
               )
      else
        assert has_element?(
                 view,
                 files_empty,
                 "This session did not produce any translated files."
               )

        assert has_element?(view, activity_empty, "This session has no recorded activity.")
      end

      refute has_element?(view, "#translation-progress-summary")
      refute has_element?(view, ".dash-empty-state")
    end
  end

  test "a content-hit session without a progress snapshot explains why there are no files", %{
    conn: conn
  } do
    user = TestHelpers.create_user("translation-content-hit@test.com", "translation-content-hit")

    {:ok, project} =
      Projects.create_project(user.account, %{handle: "content-hit", name: "Content hit"})

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "completed",
        outcome: "content_hit",
        content_hit_count: 371
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    assert has_element?(
             view,
             "#translation-progress-items .noora-table-empty-state",
             "All files are up to date. No translations were needed."
           )

    refute has_element?(view, "#translation-progress-items-body tr[id]")
  end

  test "activity replaces its empty state when an event arrives", %{conn: conn} do
    user = TestHelpers.create_user("translation-activity@test.com", "translation-activity")

    {:ok, project} =
      Projects.create_project(user.account, %{handle: "activity", name: "Activity"})

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{status: "running"})

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    assert has_element?(
             view,
             "[data-part='session-events-section'].noora-table .noora-table-empty-state"
           )

    send(
      view.pid,
      {:translation_session_event, %{event_type: "message", content: "Checking files"}}
    )

    assert has_element?(view, "[data-part='event-feed']", "Checking files")
    refute has_element?(view, "[data-part='session-events-card'] .noora-table-empty-state")
    refute has_element?(view, "[data-part='session-events-section'].noora-table")
  end

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

  test "a running translation session has a cancel action in the page header", %{conn: conn} do
    user = TestHelpers.create_user("cancel-action@test.com", "cancel-action")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "cancel-action",
        name: "Cancel action",
        github_repo_full_name: "example/cancel-action"
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

    assert has_element?(
             view,
             ".dash-page-header-actions #cancel-translation-session",
             "Cancel translation"
           )

    assert view
           |> element("#cancel-translation-session")
           |> render() =~ "data-confirm"

    view
    |> element("#cancel-translation-session")
    |> render_click()

    assert render(view) =~ "Translation cancelled."
    assert TranslationSessions.get_session!(session.id).status == "cancelled"
    refute has_element?(view, "#cancel-translation-session")
  end

  test "automatically refreshes the session status while a translation is active", %{conn: conn} do
    user =
      TestHelpers.create_user("translation-status-refresh@test.com", "translation-status-refresh")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "status-refresh",
        name: "Status refresh",
        github_repo_full_name: "example/status-refresh"
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

    {:ok, _completed} = TranslationSessions.update_session_status(session, "completed")
    send(view.pid, :refresh_translation_session)

    assert has_element?(
             view,
             "#translation-session [data-part='status'][data-status='success']",
             "Translated"
           )
  end

  test "automatically refreshes active sessions in the translations list", %{conn: conn} do
    user =
      TestHelpers.create_user("translation-list-refresh@test.com", "translation-list-refresh")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "list-refresh",
        name: "List refresh",
        github_repo_full_name: "example/list-refresh"
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
      live(conn, "/#{user.account.handle}/#{project.handle}/-/translations")

    {:ok, _completed} = TranslationSessions.update_session_status(session, "completed")
    send(view.pid, :refresh_translation_session)

    assert has_element?(view, "#translations-table [data-status='success']", "Translated")
  end

  test "opens a translation session by clicking its row", %{conn: conn} do
    user = TestHelpers.create_user("translation-row-link@test.com", "translation-row-link")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "translation-row-link",
        name: "Translation row link",
        github_repo_full_name: "example/translation-row-link"
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
      live(conn, "/#{user.account.handle}/#{project.handle}/-/translations")

    row = "#translation-session-#{session.id}"
    session_path = "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}"

    assert has_element?(view, "#{row} [data-part='row-link'][href='#{session_path}']")
    refute has_element?(view, "#translations-table", "Actions")
    refute has_element?(view, "#{row}", "View")
  end

  test "does not render a legacy pull request event beside the current pull request", %{
    conn: conn
  } do
    user =
      TestHelpers.create_user("translation-pull-request-event@test.com", "translation-pr-event")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "pull-request-event",
        name: "Pull request event",
        github_repo_full_name: "example/pull-request-event"
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

    legacy_pull_request_url = "https://github.com/example/pull-request-event/pull/42"

    TranslationSessions.broadcast_session_event(session, %{
      event_type: "pr_created",
      content: legacy_pull_request_url
    })

    refute render(view) =~ legacy_pull_request_url
  end

  test "session errors use an error alert and humanize legacy planning failures", %{conn: conn} do
    user = TestHelpers.create_user("translation-error@test.com", "translation-error")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "error-alert",
        name: "Error alert",
        github_repo_full_name: "example/error-alert"
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

    TranslationSessions.broadcast_session_event(session, %{
      event_type: "error",
      content:
        "Translation failed: {:planning_failed, \"sources must be a mapping of source patterns to target path templates\"}"
    })

    assert has_element?(
             view,
             "[data-part='session-error'][data-status='error']",
             "Translation failed"
           )

    assert has_element?(view, "[data-part='session-error']", "define sources as a mapping")
    refute render(view) =~ "planning_failed"
  end

  test "a running session shows structured progress without model reasoning", %{conn: conn} do
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

    assert has_element?(
             view,
             "#translation-session [data-part='status'][data-status='in_progress']"
           )

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

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='progress-meta']",
             "Front matter, segment 1 of 3"
           )

    refute render(view) =~ "The title is a metaphor"
    refute has_element?(view, "#translation-progress-item-0 [data-part='reasoning-output']")

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

    refute has_element?(
             view,
             "#translation-progress-item-0 + #translation-progress-item-0-expanded [data-part='live-output'] [data-part='stream']",
             "Der Titel"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 + #translation-progress-item-0-expanded [data-part='completed-segment'] summary",
             "Front matter, segment 1 of 3"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 + #translation-progress-item-0-expanded [data-part='completed-segment'] [data-part='stream']",
             "Der Titel"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='progress-meta']",
             "Content, segment 2 of 3"
           )

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_completed",
      index: 0,
      file_ref: "glossia/translate-0123456789ab",
      output_preview: "%{title: \"Der Titel\"}\n\nDer Inhalt",
      model_calls: 2
    })

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "attempt_start", attempt: 2}
    })

    refute render(view) =~ "The title is a metaphor"

    {:ok, _session} = TranslationSessions.update_session_status(session, "completed")

    assert has_element?(view, "#translation-session [data-part='status'][data-status='success']")
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
             "#translation-progress-item-0 + #translation-progress-item-0-expanded [data-part='item-failure'][data-kind='validation-empty-output']",
             "The model returned empty output"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 + #translation-progress-item-0-expanded .noora-alert[data-part='item-failure'] [data-part='description']",
             "can spend its whole output budget thinking and return nothing"
           )
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

    assert rendered =~ "Translated output"

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

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_completed",
      index: 0,
      output_preview: "# Überschrift\n\nÜbersetzter Inhalt",
      model_calls: 2
    })

    {:ok, reconnected_view, _html} =
      live(conn, "/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    assert has_element?(reconnected_view, "#translation-progress-item-0")

    assert has_element?(
             reconnected_view,
             "#translation-progress-item-0 [data-part='path']",
             "app/priv/i18n/de/example.md"
           )

    assert has_element?(
             reconnected_view,
             "#translation-progress-item-0-completed-output [data-part='output-title']",
             "Translated output preview"
           )

    assert has_element?(
             reconnected_view,
             "#translation-progress-item-0 + #translation-progress-item-0-expanded [data-part='completed-output'] [data-part='stream']",
             "Übersetzter Inhalt"
           )

    assert has_element?(
             reconnected_view,
             "#translation-progress-item-0 [data-part='progress-meta']",
             "2 model calls"
           )
  end

  test "running translation items show their status in the progress table", %{conn: conn} do
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

    assert has_element?(
             view,
             "[data-part='session-events-card'] .noora-table-empty-state",
             "No activity recorded"
           )

    assert has_element?(view, "#translation-progress-items .noora-table-empty-state")

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
             "#translation-progress-items .noora-status-badge[data-status='in_progress']",
             "Translating"
           )

    assert has_element?(view, "#translation-progress-summary-translated", "0/1 translated")
    refute has_element?(view, "#translation-progress-summary-checking")
    assert has_element?(view, "#translation-progress-summary-running", "1 in progress")
    assert has_element?(view, "#translation-progress-item-0")
    refute has_element?(view, "#translation-progress-items .noora-table-empty-state")

    refute has_element?(view, "#translation-progress-item-0 a[data-part='path']")

    assert has_element?(
             view,
             "#translation-progress-item-0 div[data-part='path'] [data-part='cell'][data-type='text'] [data-part='label']",
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
             "#translation-progress-item-0 [data-part='progress-meta'] [data-part='cell'][data-type='text']",
             "Content, segment 2 of 2 · 2 model calls"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 + #translation-progress-item-0-expanded [data-part='stream']",
             "translated front matter"
           )

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_event",
      index: 0,
      event: %{type: "text", text: "translated body"}
    })

    assert has_element?(
             view,
             "#translation-progress-item-0 + #translation-progress-item-0-expanded [data-part='stream']",
             "translated front matter"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 + #translation-progress-item-0-expanded [data-part='stream']",
             "translated body"
           )

    refute has_element?(view, ".dash-empty-state")
    refute has_element?(view, ".session-event-feed")

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_completed",
      index: 0,
      file_ref: "glossia/translate-0123456789ab",
      output_preview: "translated front matter\n\ntranslated body",
      model_calls: 2
    })

    assert has_element?(
             view,
             "#translation-progress-items .noora-status-badge[data-status='success']",
             "Done"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 a[data-part='path'][href='https://github.com/example/progress/blob/glossia/translate-0123456789ab/app/priv/i18n/de/example.md'][target='_blank'] [data-part='cell'][data-type='text'] [data-part='label']",
             "app/priv/i18n/de/example.md"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 + #translation-progress-item-0-expanded [data-part='completed-output'] [data-part='output-title']",
             "Translated output preview"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 + #translation-progress-item-0-expanded [data-part='completed-output'] [data-part='stream']",
             "translated body"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 [data-part='progress-meta']",
             "2 model calls"
           )

    refute has_element?(
             view,
             "#translation-session [data-part='metadata'] a",
             "View pull request"
           )

    {:ok, _session} =
      TranslationSessions.update_session_publication(session, %{
        publication_branch: "glossia/translate-0123456789ab",
        publication_commit_sha: "translated-commit",
        pull_request_url: "https://github.com/example/progress/pull/42"
      })

    assert has_element?(
             view,
             "#translation-session [data-part='metadata'] a[href='https://github.com/example/progress/pull/42'][target='_blank'][rel='noopener noreferrer']",
             "View pull request"
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
             "#translation-progress-items .noora-status-badge[data-status='error']",
             "Failed"
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

    assert has_element?(
             view,
             "#translation-progress-items .noora-status-badge[data-status='error']",
             "Failed"
           )

    {:ok, _session} = TranslationSessions.update_session_status(session, "running")

    refute has_element?(view, "#translation-progress-item-0")
    refute has_element?(view, "#translation-progress-failures")
    assert has_element?(view, "#translation-progress-items .noora-table-empty-state")

    assert has_element?(
             view,
             "[data-part='session-events-card'] .noora-table-empty-state",
             "No activity recorded"
           )
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
             "#translation-progress .noora-button[data-part='failure-action'][href='https://api.together.ai/settings/billing']",
             "Review provider billing"
           )

    refute has_element?(
             view,
             "#translation-progress [data-part='failure-summary'] [data-part='item-diagnostics']"
           )

    assert has_element?(
             view,
             "#translation-progress .noora-alert[data-part='failure-summary'][data-type='secondary'][data-status='error'][data-size='large']"
           )

    Enum.each(0..1, fn index ->
      assert has_element?(
               view,
               "#translation-progress-item-#{index} + #translation-progress-item-#{index}-expanded .noora-alert[data-part='item-failure'][data-kind='provider-credit'][data-type='primary'][data-status='error']",
               "This file could not be translated because the model provider account has no remaining credit."
             )

      assert has_element?(
               view,
               "#translation-progress-item-#{index} + #translation-progress-item-#{index}-expanded [data-part='item-diagnostics'] summary",
               "Diagnostic details"
             )

      assert has_element?(
               view,
               "#translation-progress-item-#{index} + #translation-progress-item-#{index}-expanded [data-part='item-diagnostics'][id][phx-mounted] summary [data-part='disclosure-icon'][aria-hidden='true']"
             )

      assert has_element?(
               view,
               "#translation-progress-item-#{index} + #translation-progress-item-#{index}-expanded [data-part='item-diagnostics']",
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
             "#translation-progress-item-0 + #translation-progress-item-0-expanded [data-part='item-failure'][data-kind='validation-command']",
             "The validation command rejected the translated output for this file."
           )

    assert has_element?(
             view,
             "#translation-progress-item-0 + #translation-progress-item-0-expanded [data-part='partial-output'] [data-part='output-title']",
             "Incomplete output"
           )

    refute has_element?(view, "#translation-progress [data-part='failure-summary']")
    refute render(view) =~ "repository-secret"
  end

  test "publication failures name the publication stage and show only safe diagnostics", %{
    conn: conn
  } do
    user = TestHelpers.create_user("translation-publication@test.com", "translation-publication")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "publication-failure",
        name: "Publication failure"
      })

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        status: "running",
        source_language: "en",
        target_languages: ["de"]
      })

    conn = init_test_session(conn, %{user_id: user.id})

    {:ok, view, _html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    TranslationSessions.broadcast_session_event(session, %{type: "plan", total: 1})

    TranslationSessions.broadcast_session_event(session, %{
      type: "item_failed",
      index: 0,
      output_path: "docs/de/guide.md",
      locale: "de",
      reason: %{
        kind: "publication-failed",
        scope: "session",
        publication_code: "artifact-unreadable",
        publication_file_error: "enoent",
        publication_message: "TOKEN=private-output"
      }
    })

    assert has_element?(
             view,
             "#translation-progress [data-part='failure-summary'][data-kind='publication-failed']",
             "Translated files could not be published"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0-expanded [data-part='item-diagnostics']",
             "A translated output or lockfile could not be read"
           )

    assert has_element?(
             view,
             "#translation-progress-item-0-expanded [data-part='item-diagnostics']",
             "enoent"
           )

    refute render(view) =~ "private-output"
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
             "#translation-progress-item-0 + #translation-progress-item-0-expanded [data-part='item-failure'][data-kind='validation-empty-output']",
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

    assert has_element?(
             view,
             "#translation-progress-items .noora-table-empty-state",
             "All files are up to date. No translations were needed."
           )

    # "No translations needed" and "231 up to date" say the same thing.
    refute has_element?(view, "#translation-progress-summary-skipped")
    refute has_element?(view, "#translation-progress-summary-running")
    refute has_element?(view, "#translation-progress-summary-checking")

    {:ok, reconnected_view, _html} =
      live(conn, ~p"/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    assert has_element?(
             reconnected_view,
             "#translation-progress-items .noora-table-empty-state",
             "All files are up to date. No translations were needed."
           )
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
