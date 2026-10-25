defmodule GlossiaWeb.TokiLiveTest do
  use GlossiaWeb.ConnCase, async: true
  use Oban.Testing, repo: Glossia.Repo

  import Phoenix.LiveViewTest

  alias Glossia.{
    Accounts,
    LinguisticReviews,
    Organizations,
    Projects,
    Repo,
    TestHelpers,
    Toki,
    TranslationSessions
  }

  alias Glossia.LinguisticReviews.Review
  alias Glossia.Toki.{Conversation, Message}

  setup %{conn: conn} do
    user =
      TestHelpers.create_user(
        "toki-web-#{System.unique_integer([:positive])}@test.com",
        "toki-web"
      )

    {:ok, user} = Accounts.update_user_profile(user, %{name: "Ana"})
    user = Repo.preload(user, :account)
    {:ok, user} = Accounts.update_user_fluent_languages(user, ["es"])
    {:ok, project} = Projects.create_project(user.account, %{handle: "docs", name: "Docs"})
    project = Repo.preload(project, :account)

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{status: "running"})

    %{
      user: user,
      project: project,
      session: session,
      conn: init_test_session(conn, %{user_id: user.id})
    }
  end

  test "empty list, navigation and a new private conversation", c do
    {:ok, view, _} = live(c.conn, ~p"/#{c.user.account.handle}/#{c.project.handle}/-/toki")
    assert has_element?(view, "#toki-page .noora-table-empty-state", "No conversations yet")
    assert has_element?(view, "#platform-sidebar a[href$='/-/toki']", "Toki")
    view |> element("#new-toki-conversation") |> render_click()
    conversation = Repo.get_by!(Conversation, user_id: c.user.id, project_id: c.project.id)

    assert_redirect(
      view,
      ~p"/#{c.user.account.handle}/#{c.project.handle}/-/toki/#{conversation.id}"
    )

    {:ok, detail, _} =
      live(c.conn, ~p"/#{c.user.account.handle}/#{c.project.handle}/-/toki/#{conversation.id}")

    assert has_element?(detail, "#toki-discussion", "Talk it through with Toki")
    refute has_element?(detail, "#toki-approval")
    refute has_element?(detail, "#toki-page input[type='file']")
  end

  test "shared goal appears in history and translation detail, with fluent participants", c do
    review = request(c)
    {:ok, view, _} = live(c.conn, ~p"/#{c.user.account.handle}/#{c.project.handle}/-/toki")
    assert has_element?(view, "#toki-thread-#{review.conversation.id}", "Help requested")
    {:ok, detail, _} = live(c.conn, goal_path(c, review))
    assert has_element?(detail, "#toki-goal", "Ana")
    assert has_element?(detail, "#toki-approve[disabled]")
    assert has_element?(detail, "#toki-goal", "Create a branch.")

    {:ok, overview, _} = live(c.conn, ~p"/#{c.user.account.handle}/#{c.project.handle}")

    assert has_element?(
             overview,
             "#project-toki-goals a[href='#{goal_path(c, review)}']",
             "Which kind of branch?"
           )

    {:ok, session_view, _} =
      live(c.conn, ~p"/#{c.user.account.handle}/#{c.project.handle}/-/sessions/#{c.session.id}")

    assert has_element?(
             session_view,
             "#translation-linguistic-reviews a[href='#{goal_path(c, review)}']",
             "Which kind of branch?"
           )
  end

  test "opening question cannot be approved, including forged events", c do
    review = request(c)
    {:ok, view, _} = live(c.conn, goal_path(c, review))
    opening = Repo.get_by!(Message, conversation_id: review.conversation.id, role: "assistant")

    render_submit(view, "resolve", %{
      "resolution" => %{"resolution_message_id" => opening.id, "guidance" => "Keep this draft"}
    })

    assert has_element?(view, "#toki-error", "discussion changed")
    assert has_element?(view, "#toki-guidance", "Keep this draft")
    assert Repo.get!(Review, review.id).status == "open"
  end

  test "send uses the current actor and preserves a draft while busy and through refresh", c do
    review = request(c)
    {:ok, view, _} = live(c.conn, goal_path(c, review))

    view
    |> form("#toki-composer", message: %{content: "This is source control."})
    |> render_submit()

    message = Repo.get_by!(Message, conversation_id: review.conversation.id, role: "user")
    assert message.user_id == c.user.id
    assert message.content == "This is source control."
    assert has_element?(view, "#toki-messages", "Ana")

    Oban.Testing.with_testing_mode(:manual, fn ->
      {:ok, _} =
        Toki.send_message(c.user, c.project, review.conversation.id, %{
          "id" => Ecto.UUID.generate(),
          "content" => "A later turn is still queued."
        })

      send(view.pid, :refresh_toki)
      assert has_element?(view, "#toki-busy")
      count = Repo.aggregate(Message, :count, :id)
      render_submit(view, "send_message", %{"message" => %{"content" => "Do not lose this"}})
      assert has_element?(view, "#toki-error", "Toki is replying")
      send(view.pid, :refresh_toki)
      assert has_element?(view, "#toki-content", "Do not lose this")
      assert Repo.aggregate(Message, :count, :id) == count
    end)
  end

  test "approval binds the latest completed reply and continues without durable guidance by default",
       c do
    review = request(c)
    reply = complete_reply(c, review)
    {:ok, view, _} = live(c.conn, goal_path(c, review))
    assert has_element?(view, "#toki-proposed-decision", reply.content)

    Oban.Testing.with_testing_mode(:manual, fn ->
      {:ok, _} = LinguisticReviews.pause(c.session.id)
      view |> form("#toki-resolution") |> render_submit()
      saved = Repo.get!(Review, review.id)
      assert saved.resolution_message_id == reply.id
      assert saved.answer == reply.content
      assert is_nil(saved.guidance)
      assert is_nil(saved.context_path)
      assert has_element?(view, "#toki-goal-closed", "read-only")
      assert has_element?(view, "#toki-continuation[href$='#{saved.resumed_session_id}']")
      assert has_element?(view, "#toki-content[disabled]")
      refute has_element?(view, "#toki-approve")
    end)
  end

  test "durable project guidance is independent of the approved decision", c do
    review = request(c)
    reply = complete_reply(c, review)
    {:ok, view, _} = live(c.conn, goal_path(c, review))
    render_click(view, "guidance_scope", %{"scope" => "project"})

    view
    |> form("#toki-resolution", resolution: %{guidance: "Branch always means source control."})
    |> render_submit()

    saved = Repo.get!(Review, review.id)
    assert saved.answer == reply.content
    assert saved.guidance == "Branch always means source control."
    assert saved.context_path == "L10N.md"
  end

  test "a concurrent turn rejects approval as busy and then outdated, retaining guidance", c do
    review = request(c)
    first = complete_reply(c, review)
    {:ok, view, _} = live(c.conn, goal_path(c, review))

    Oban.Testing.with_testing_mode(:manual, fn ->
      id = Ecto.UUID.generate()

      {:ok, _} =
        Toki.send_message(c.user, c.project, review.conversation.id, %{
          "id" => id,
          "content" => "Another interpretation"
        })

      attrs = %{
        "resolution" => %{
          "resolution_message_id" => first.id,
          "guidance" => "Still drafting",
          "context_scope" => "locale"
        }
      }

      render_submit(view, "resolve", attrs)
      assert has_element?(view, "#toki-error", "Toki is replying")
      {:ok, turn} = Toki.claim(id)
      {:ok, _} = Toki.finish(turn, {:ok, "A revised decision."})
      render_submit(view, "resolve", attrs)
      assert has_element?(view, "#toki-error", "discussion changed")
      assert has_element?(view, "#toki-guidance", "Still drafting")
      assert has_element?(view, "#toki-proposed-decision", "A revised decision.")
      assert Repo.get!(Review, review.id).status == "open"
    end)
  end

  test "stale translation closes the goal without losing an unsent draft", c do
    review = request(c)
    {:ok, view, _} = live(c.conn, goal_path(c, review))
    view |> form("#toki-composer", message: %{content: "Unsent thought"}) |> render_change()

    view
    |> form("#toki-resolution", resolution: %{guidance: "Unsent guidance"})
    |> render_change()

    c.session |> Ecto.Changeset.change(status: "cancelled") |> Repo.update!()
    send(view.pid, :refresh_toki)
    assert has_element?(view, "#toki-goal-closed", "no longer current")
    assert has_element?(view, "#toki-content[disabled]", "Unsent thought")
    assert has_element?(view, "#toki-guidance[readonly]", "Unsent guidance")
    assert has_element?(view, "#toki-draft-recovery", "copy it")
    refute has_element?(view, "#toki-approve")
  end

  test "approval in another browser preserves unsaved guidance through polling", c do
    review = request(c)
    reply = complete_reply(c, review)
    {:ok, view, _} = live(c.conn, goal_path(c, review))
    view |> form("#toki-resolution", resolution: %{guidance: "My local draft"}) |> render_change()

    {:ok, _} =
      LinguisticReviews.answer(c.user, c.project, c.session.id, review.id, %{
        "answer" => reply.content,
        "resolution_message_id" => reply.id
      })

    send(view.pid, :refresh_toki)
    assert has_element?(view, "#toki-goal-closed", "Decision approved")
    assert has_element?(view, "#toki-guidance[readonly]", "My local draft")
    assert has_element?(view, "#toki-draft-recovery", "has not been applied")
    refute has_element?(view, "#toki-approve")
  end

  test "private history never leaks to another account", c do
    {:ok, detail} = Toki.create_conversation(c.user, c.project, %{"id" => Ecto.UUID.generate()})

    outsider =
      TestHelpers.create_user(
        "outsider-#{System.unique_integer([:positive])}@test.com",
        "outsider"
      )

    {:ok, other_project} =
      Projects.create_project(outsider.account, %{handle: "docs", name: "Other"})

    conn = init_test_session(build_conn(), %{user_id: outsider.id})

    {:ok, view, _} =
      live(
        conn,
        ~p"/#{outsider.account.handle}/#{other_project.handle}/-/toki/#{detail.conversation.id}"
      )

    assert has_element?(view, "#toki-unavailable")
    refute has_element?(view, "#toki-discussion")
  end

  test "fluent teammates see one shared thread, and membership removal revokes access", c do
    teammate =
      TestHelpers.create_user("mate-#{System.unique_integer([:positive])}@test.com", "mate")

    {:ok, teammate} = Accounts.update_user_fluent_languages(teammate, ["es-MX"])

    {:ok, %{organization: org, account: account}} =
      Organizations.create_organization(c.user, %{
        handle: "shared-#{System.unique_integer([:positive])}"
      })

    {:ok, _} = Organizations.add_member(org, teammate)
    {:ok, project} = Projects.create_project(account, %{handle: "docs", name: "Shared docs"})
    project = Repo.preload(project, :account)
    {:ok, session} = TranslationSessions.create_session(account, project, %{status: "running"})
    shared = %{c | project: project, session: session, user: %{c.user | account: account}}
    review = request(shared)
    conn = init_test_session(build_conn(), %{user_id: teammate.id})
    {:ok, view, _} = live(conn, goal_path(shared, review))
    assert has_element?(view, "#toki-goal [data-part='participants'] .noora-tag", "Ana")
    assert length(LinguisticReviews.serialize(review).participants) == 2
    assert {1, _} = Organizations.remove_member(org, teammate)
    render_submit(view, "send_message", %{"message" => %{"content" => "Not authorized anymore"}})
    assert has_element?(view, "#toki-unavailable")
    refute Repo.get_by(Message, conversation_id: review.conversation.id, role: "user")
  end

  defp request(c) do
    {:ok, review} =
      LinguisticReviews.request(
        c.session.id,
        %{
          source_path: "start.txt",
          output_path: "es/start.txt",
          locale: "es",
          context_targets: %{
            "locale" => %{"path" => "L10N/es.md", "digest" => nil},
            "project" => %{"path" => "L10N.md", "digest" => nil}
          }
        },
        String.duplicate("a", 64),
        %{
          reason: "ambiguity",
          question: "Which kind of branch?",
          source: "Create a branch.",
          translation: "Crea una rama."
        }
      )

    Repo.preload(review, :conversation)
  end

  defp complete_reply(c, review) do
    Oban.Testing.with_testing_mode(:manual, fn ->
      id = Ecto.UUID.generate()

      {:ok, _} =
        Toki.send_message(c.user, c.project, review.conversation.id, %{
          "id" => id,
          "content" => "This refers to source control."
        })

      {:ok, message} = Toki.claim(id)
      {:ok, _} = Toki.finish(message, {:ok, "Use the source-control meaning, not a tree branch."})
      Repo.get_by!(Message, reply_to_id: id)
    end)
  end

  defp goal_path(c, review),
    do: ~p"/#{c.user.account.handle}/#{c.project.handle}/-/toki/#{review.conversation.id}"
end
