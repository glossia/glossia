defmodule GlossiaWeb.Api.MobileTranslationSourceTest do
  use GlossiaWeb.ConnCase, async: true
  use Mimic
  use Oban.Testing, repo: Glossia.Repo

  alias Glossia.{
    MemberPermissions,
    Organizations,
    Projects,
    Repo,
    TestHelpers,
    Toki,
    TranslationSessions
  }

  alias Glossia.Toki.{Conversation, Message, ReplyWorker}

  @scopes ~w(toki:read toki:write translation:read)

  setup %{conn: conn} do
    unique = System.unique_integer([:positive])
    ip = rem(unique, 65_000)
    conn = %{conn | remote_ip: {127, 2, div(ip, 256), rem(ip, 256)}}
    owner = TestHelpers.create_user("source-#{unique}@test.com", "source-#{unique}")
    outsider = TestHelpers.create_user("outsider-#{unique}@test.com", "outsider-#{unique}")
    {:ok, project} = Projects.create_project(owner.account, %{handle: "app", name: "App"})
    {:ok, other} = Projects.create_project(owner.account, %{handle: "other", name: "Other"})
    project = Repo.preload(project, :account)
    other = Repo.preload(other, :account)

    {:ok, session} =
      TranslationSessions.create_session(owner.account, project, %{
        status: "completed",
        commit_sha: "source-sha",
        commit_message: "Source commit",
        source_language: "en",
        target_languages: ["ja"],
        summary: "PRIVATE SOURCE SUMMARY"
      })

    {:ok, foreign} =
      TranslationSessions.create_session(owner.account, other, %{summary: "FOREIGN"})

    %{
      conn: conn,
      owner: owner,
      outsider: outsider,
      project: project,
      other: other,
      session: session,
      foreign: foreign
    }
  end

  test "translation detail performs an exact scoped lookup without pagination or list fallback",
       c do
    stub(TranslationSessions, :list_project_sessions, fn _, _ ->
      flunk("detail must not list sessions")
    end)

    path = source_path(c.project, c.session.id)
    auth = TestHelpers.authenticate(c.conn, c.owner, ["translation:read"])
    body = auth |> get(path, %{page: "invalid", page_size: 0}) |> json_response(200)
    assert body["session"]["id"] == c.session.id
    assert body["session"]["commit_sha"] == "source-sha"
    assert body["session"]["summary"] == "PRIVATE SOURCE SUMMARY"

    assert Enum.sort(Map.keys(body["session"])) ==
             Enum.sort(
               ~w(id status commit_message commit_sha source_language target_languages translated_content_count inserted_at summary)
             )

    for id <- ["bad", Ecto.UUID.generate(), c.foreign.id] do
      assert auth |> get(source_path(c.project, id)) |> json_response(404) == %{
               "error" => "not_found"
             }
    end

    assert c.conn |> get(path) |> json_response(401)
    denied = c.conn |> TestHelpers.authenticate(c.owner, ["toki:read"]) |> get(path)
    assert json_response(denied, 403)["required_scope"] == "translation:read"
    assert get_resp_header(denied, "www-authenticate") != []

    assert c.conn
           |> TestHelpers.authenticate(c.outsider, ["translation:read"])
           |> get(path)
           |> json_response(403)

    attrs = %{id: Ecto.UUID.generate(), translation_session_id: c.session.id}
    assert c.conn |> post(conversations_path(c.project), attrs) |> json_response(401)

    assert c.conn
           |> TestHelpers.authenticate(c.outsider, @scopes)
           |> post(conversations_path(c.project), attrs)
           |> json_response(403)

    assert all_enqueued(worker: ReplyWorker) == []
  end

  test "creation persists only the immutable reference, and UUID retries must match it", c do
    auth = TestHelpers.authenticate(c.conn, c.owner, @scopes)
    id = Ecto.UUID.generate()

    attrs = %{
      id: id,
      translation_session_id: c.session.id,
      summary: "CLIENT FORGERY",
      content: "Do not send",
      source: %{summary: "CLIENT FORGERY"}
    }

    body = auth |> post(conversations_path(c.project), attrs) |> json_response(201)
    assert body["conversation"]["translation_session_id"] == c.session.id
    assert body["conversation"]["title"] == "New conversation"
    assert body["conversation"]["status"] == "completed"
    assert body["messages"] == []
    assert Repo.get!(Conversation, id).translation_session_id == c.session.id
    assert Repo.aggregate(Message, :count) == 0
    assert all_enqueued(worker: ReplyWorker) == []
    assert auth |> post(conversations_path(c.project), attrs) |> json_response(201) == body
    assert auth |> get(conversation_path(c.project, id)) |> json_response(200) == body

    assert [%{"translation_session_id" => origin}] =
             auth
             |> get(conversations_path(c.project))
             |> json_response(200)
             |> Map.fetch!("conversations")

    assert origin == c.session.id

    for origin <- [nil, Ecto.UUID.generate(), c.foreign.id] do
      assert auth
             |> post(conversations_path(c.project), %{id: id, translation_session_id: origin})
             |> json_response(409) == %{"error" => "id_conflict"}
    end

    {:ok, unlinked} =
      Toki.create_conversation(c.owner, c.project, %{"id" => Ecto.UUID.generate()})

    assert auth
           |> post(conversations_path(c.project), %{
             id: unlinked.conversation.id,
             translation_session_id: c.session.id
           })
           |> json_response(409)

    assert auth
           |> get(conversation_path(c.project, unlinked.conversation.id))
           |> json_response(200)
           |> get_in(["conversation", "translation_session_id"]) == nil

    for origin <- [Ecto.UUID.generate(), c.foreign.id] do
      assert auth
             |> post(conversations_path(c.project), %{
               id: Ecto.UUID.generate(),
               translation_session_id: origin
             })
             |> json_response(404)
    end

    for origin <- ["bad", 123, %{}] do
      assert auth
             |> post(conversations_path(c.project), %{
               id: Ecto.UUID.generate(),
               translation_session_id: origin
             })
             |> json_response(422)
    end

    changeset =
      Conversation.changeset(Repo.get!(Conversation, id), %{translation_session_id: nil})

    refute changeset.valid?
    assert all_enqueued(worker: ReplyWorker) == []
  end

  test "reduced scopes cannot obtain source-linked metadata or history on reads, sends or replays",
       c do
    auth = TestHelpers.authenticate(c.conn, c.owner, @scopes)
    reduced = TestHelpers.authenticate(c.conn, c.owner, ~w(toki:read toki:write))
    id = Ecto.UUID.generate()
    attrs = %{id: id, translation_session_id: c.session.id}
    assert auth |> post(conversations_path(c.project), attrs) |> json_response(201)
    message_id = Ecto.UUID.generate()

    payload = %{
      id: message_id,
      content: "Explain this source",
      translation_session_id: c.foreign.id,
      summary: "CLIENT FORGERY"
    }

    first = submit(auth, message_path(c.project, id), payload) |> json_response(202)
    assert first["conversation"]["translation_session_id"] == c.session.id
    assert submit(auth, message_path(c.project, id), payload) |> json_response(202) == first
    assert [%Oban.Job{}] = all_enqueued(worker: ReplyWorker)

    Repo.insert!(%Message{
      conversation_id: id,
      role: "assistant",
      content: "PRIVATE SOURCE SUMMARY",
      status: "completed"
    })

    for response <- [
          get(reduced, conversation_path(c.project, id)),
          post(reduced, conversations_path(c.project), attrs),
          post(reduced, conversations_path(c.project), %{
            id: Ecto.UUID.generate(),
            translation_session_id: c.session.id
          }),
          submit(reduced, message_path(c.project, id), payload),
          submit(reduced, message_path(c.project, id), %{id: Ecto.UUID.generate(), content: "New"})
        ] do
      assert json_response(response, 403) == %{
               "error" => "insufficient_scope",
               "required_scope" => "translation:read"
             }

      refute response.resp_body =~ "PRIVATE SOURCE"
      refute response.resp_body =~ c.session.id
    end

    list = reduced |> get(conversations_path(c.project)) |> json_response(200)
    assert list["conversations"] == []
    assert list["meta"]["total_count"] == 0
    assert length(all_enqueued(worker: ReplyWorker)) == 1
    assert Repo.aggregate(Message, :count) == 2
  end

  test "translation membership permission is required independently of Toki permission", c do
    {:ok, %{organization: organization, account: account}} =
      Organizations.create_organization(c.owner, %{
        handle: "source-org-#{System.unique_integer([:positive])}"
      })

    {:ok, _} = Organizations.add_member(organization, c.outsider)

    {:ok, _} =
      MemberPermissions.update(
        organization,
        c.owner,
        c.outsider,
        ~w(project:read toki:read toki:write)
      )

    {:ok, project} = Projects.create_project(account, %{handle: "app", name: "App"})
    project = Repo.preload(project, :account)
    {:ok, source} = TranslationSessions.create_session(account, project, %{summary: "ORG SECRET"})
    auth = TestHelpers.authenticate(c.conn, c.outsider, @scopes)
    attrs = %{id: Ecto.UUID.generate(), translation_session_id: source.id}
    assert auth |> get(source_path(project, source.id)) |> json_response(403)
    assert auth |> post(conversations_path(project), attrs) |> json_response(403)

    {:ok, _} =
      MemberPermissions.update(
        organization,
        c.owner,
        c.outsider,
        ~w(project:read toki:read toki:write translation:read)
      )

    assert auth |> post(conversations_path(project), attrs) |> json_response(201)

    {:ok, _} =
      MemberPermissions.update(
        organization,
        c.owner,
        c.outsider,
        ~w(project:read toki:read toki:write)
      )

    assert auth |> post(conversations_path(project), attrs) |> json_response(403)
    assert auth |> get(conversation_path(project, attrs.id)) |> json_response(403)

    assert auth
           |> get(conversations_path(project))
           |> json_response(200)
           |> get_in(["meta", "total_count"]) == 0
  end

  defp source_path(project, id),
    do: ~p"/api/#{project.account.handle}/projects/#{project.handle}/translations/#{id}"

  defp conversations_path(project),
    do: ~p"/api/#{project.account.handle}/projects/#{project.handle}/toki/conversations"

  defp conversation_path(project, id),
    do: ~p"/api/#{project.account.handle}/projects/#{project.handle}/toki/conversations/#{id}"

  defp message_path(project, id),
    do:
      ~p"/api/#{project.account.handle}/projects/#{project.handle}/toki/conversations/#{id}/messages"

  defp submit(conn, path, attrs),
    do: Oban.Testing.with_testing_mode(:manual, fn -> post(conn, path, attrs) end)
end
