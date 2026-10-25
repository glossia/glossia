defmodule GlossiaWeb.Api.MobileApiTest do
  use GlossiaWeb.ConnCase, async: false
  use Mimic
  use Oban.Testing, repo: Glossia.Repo

  import Oban.Testing, only: [with_testing_mode: 2]

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

  @scopes ~w(user:read translation:read analytics:read toki:read toki:write)

  setup %{conn: conn} do
    previous = Application.get_env(:glossia, Glossia.Translations, [])
    Application.put_env(:glossia, Glossia.Translations, [])
    on_exit(fn -> Application.put_env(:glossia, Glossia.Translations, previous) end)
    owner = TestHelpers.create_user("mobile-owner@test.com", "mobile-owner")
    outsider = TestHelpers.create_user("mobile-outsider@test.com", "mobile-outsider")
    {:ok, project} = Projects.create_project(owner.account, %{handle: "mobile", name: "Mobile"})

    {:ok, other_project} =
      Projects.create_project(owner.account, %{handle: "other", name: "Other"})

    project = Repo.preload(project, :account)
    other_project = Repo.preload(other_project, :account)
    ip = rem(System.unique_integer([:positive]), 65_000)
    conn = %{conn | remote_ip: {127, 1, div(ip, 256), rem(ip, 256)}}

    %{
      conn: conn,
      owner: owner,
      outsider: outsider,
      project: project,
      other_project: other_project
    }
  end

  test "me returns only the actor's profile and server version", %{conn: conn, owner: owner} do
    response = conn |> TestHelpers.authenticate(owner, ["user:read"]) |> get(~p"/api/me")
    body = json_response(response, 200)

    assert body["user"] == %{
             "id" => owner.id,
             "email" => owner.email,
             "name" => nil,
             "handle" => owner.account.handle
           }

    assert is_binary(body["server_version"])

    response = conn |> TestHelpers.authenticate(owner, []) |> get(~p"/api/me")
    assert json_response(response, 403)["required_scope"] == "user:read"
    assert json_response(get(conn, ~p"/api/me"), 401)
  end

  test "every read requires its dedicated token scope and rejects private-project outsiders",
       context do
    %{conn: conn, owner: owner, outsider: outsider, project: project} = context

    for {path, scope} <- [
          {~p"/api/#{owner.account.handle}/projects/#{project.handle}/translations",
           "translation:read"},
          {~p"/api/#{owner.account.handle}/projects/#{project.handle}/analytics",
           "analytics:read"},
          {conversations_path(project), "toki:read"}
        ] do
      assert json_response(get(conn, path), 401)
      response = conn |> TestHelpers.authenticate(owner, ["project:read"]) |> get(path)
      assert json_response(response, 403)["required_scope"] == scope
      assert [header] = get_resp_header(response, "www-authenticate")
      assert header =~ scope
      response = conn |> TestHelpers.authenticate(outsider, [scope]) |> get(path)
      assert response.status == 403
    end
  end

  test "translations paginate real project data without leaking another project", context do
    %{conn: conn, owner: owner, project: project, other_project: other} = context

    sessions =
      for i <- 1..3 do
        {:ok, session} =
          TranslationSessions.create_session(owner.account, project, %{
            status: "completed",
            commit_message: "Change #{i}",
            source_language: "en",
            target_languages: ["es"],
            translated_content_count: i,
            summary: "Translated #{i} documents"
          })

        session
      end

    {:ok, _} =
      TranslationSessions.create_session(owner.account, other, %{
        status: "failed",
        commit_message: "Private other"
      })

    auth = TestHelpers.authenticate(conn, owner, ["translation:read"])

    first =
      auth
      |> get(~p"/api/#{owner.account.handle}/projects/#{project.handle}/translations?page_size=2")
      |> json_response(200)

    second =
      auth
      |> get(
        ~p"/api/#{owner.account.handle}/projects/#{project.handle}/translations?page=2&page_size=2"
      )
      |> json_response(200)

    assert first["meta"]["has_next_page?"]
    refute second["meta"]["has_next_page?"]
    assert second["meta"]["total_count"] == 3

    assert Enum.sort(Enum.map(first["sessions"] ++ second["sessions"], & &1["id"])) ==
             Enum.sort(Enum.map(sessions, & &1.id))

    assert Map.keys(hd(first["sessions"])) |> Enum.sort() ==
             Enum.sort(
               ~w(id status commit_message source_language target_languages translated_content_count inserted_at summary)
             )

    for params <- [%{page: 0}, %{page: "oops"}, %{page_size: 51}, %{page_size: 0}] do
      assert auth
             |> get(
               ~p"/api/#{owner.account.handle}/projects/#{project.handle}/translations?#{params}"
             )
             |> json_response(400)
    end
  end

  test "analytics uses actual project events and a bounded reporting window", context do
    %{conn: conn, owner: owner, project: project, other_project: other} = context
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    insert_event(project.id, DateTime.add(now, -60), "/inside", "DE", 1)
    insert_event(project.id, DateTime.add(now, -40 * 86_400), "/old", "FR", 2)
    insert_event(other.id, DateTime.add(now, -60), "/foreign", "US", 3)
    auth = TestHelpers.authenticate(conn, owner, ["analytics:read"])

    body =
      auth
      |> get(~p"/api/#{owner.account.handle}/projects/#{project.handle}/analytics")
      |> json_response(200)

    assert body["days"] == 30

    assert body["summary"] == %{
             "pageviews" => 1,
             "unique_visitors" => 1,
             "locale_gap_visits" => 1,
             "top_country" => "DE",
             "top_browser_language" => "ja"
           }

    assert body["top_pages"] == [%{"pathname" => "/inside", "pageviews" => 1}]

    body =
      auth
      |> get(~p"/api/#{owner.account.handle}/projects/#{project.handle}/analytics?days=60")
      |> json_response(200)

    assert body["summary"]["pageviews"] == 2

    for days <- [0, 366, "invalid"] do
      assert auth
             |> get(
               ~p"/api/#{owner.account.handle}/projects/#{project.handle}/analytics?days=#{days}"
             )
             |> json_response(400)
    end
  end

  test "public account read semantics are preserved, without making Toki histories public",
       context do
    %{conn: conn, owner: owner, outsider: outsider, project: project} = context
    Repo.update!(Ecto.Changeset.change(owner.account, visibility: "public"))
    {:ok, detail} = Toki.create_conversation(owner, project, %{"id" => Ecto.UUID.generate()})
    auth = TestHelpers.authenticate(conn, outsider, @scopes)

    assert auth
           |> get(~p"/api/#{owner.account.handle}/projects/#{project.handle}/translations")
           |> json_response(200)

    assert auth
           |> get(conversations_path(project))
           |> json_response(200)
           |> Map.fetch!("conversations") == []

    assert auth |> get(conversation_path(project, detail.conversation.id)) |> json_response(404)

    assert auth
           |> post(conversations_path(project), %{id: Ecto.UUID.generate()})
           |> json_response(403)
  end

  test "conversation creation and UUID replay are private, project-scoped, and idempotent",
       context do
    %{conn: conn, owner: owner, project: project, other_project: other} = context
    id = Ecto.UUID.generate()
    auth = TestHelpers.authenticate(conn, owner, ["toki:write", "toki:read"])

    first =
      auth
      |> post(conversations_path(project), %{id: id, user_id: context.outsider.id})
      |> json_response(201)

    replay = auth |> post(conversations_path(project), %{id: id}) |> json_response(201)
    assert first == replay
    assert first["messages"] == []
    assert first["conversation"]["status"] == "completed"
    assert Repo.aggregate(Conversation, :count) == 1
    assert auth |> post(conversations_path(other), %{id: id}) |> json_response(409)
    assert auth |> get(conversation_path(other, id)) |> json_response(404)
    assert auth |> post(conversations_path(project), %{id: "bad"}) |> json_response(422)
    assert auth |> post(conversations_path(project), %{}) |> json_response(422)
  end

  test "Toki writes require authentication, write scope, and project authorization", context do
    %{conn: conn, owner: owner, outsider: outsider, project: project} = context
    id = Ecto.UUID.generate()
    assert conn |> post(conversations_path(project), %{id: id}) |> json_response(401)

    response =
      conn
      |> TestHelpers.authenticate(owner, ["toki:read"])
      |> post(conversations_path(project), %{id: id})

    assert json_response(response, 403)["required_scope"] == "toki:write"

    assert conn
           |> TestHelpers.authenticate(outsider, ["toki:write"])
           |> post(conversations_path(project), %{id: id})
           |> json_response(403)

    {:ok, _} = Toki.create_conversation(owner, project, %{"id" => id})

    assert conn
           |> TestHelpers.authenticate(owner, ["toki:read"])
           |> post(message_path(project, id), %{id: Ecto.UUID.generate(), content: "Hello"})
           |> json_response(403)
  end

  test "conversation pagination is real and stable, never includes foreign users or projects",
       context do
    %{conn: conn, owner: owner, outsider: outsider, project: project, other_project: other} =
      context

    ids =
      for _ <- 1..3 do
        id = Ecto.UUID.generate()
        {:ok, _} = Toki.create_conversation(owner, project, %{"id" => id})
        id
      end

    {:ok, _} = Toki.create_conversation(owner, other, %{"id" => Ecto.UUID.generate()})
    Repo.insert!(%Conversation{user_id: outsider.id, project_id: project.id})
    auth = TestHelpers.authenticate(conn, owner, ["toki:read"])

    first =
      auth
      |> get(
        ~p"/api/#{project.account.handle}/projects/#{project.handle}/toki/conversations?page_size=2"
      )
      |> json_response(200)

    second =
      auth
      |> get(
        ~p"/api/#{project.account.handle}/projects/#{project.handle}/toki/conversations?page=2&page_size=2"
      )
      |> json_response(200)

    assert first["meta"]["has_next_page?"]
    refute second["meta"]["has_next_page?"]
    assert first["meta"]["total_count"] == 3

    assert Enum.sort(Enum.map(first["conversations"] ++ second["conversations"], & &1["id"])) ==
             Enum.sort(ids)

    assert auth
           |> get(
             ~p"/api/#{project.account.handle}/projects/#{project.handle}/toki/conversations?page_size=999"
           )
           |> json_response(400)
  end

  test "member scope overrides and administrators cannot authorize someone else's private history",
       context do
    %{conn: conn, owner: owner, outsider: member} = context

    {:ok, %{organization: organization, account: account}} =
      Organizations.create_organization(owner, %{
        handle: "mobile-org-#{System.unique_integer([:positive])}"
      })

    {:ok, _} = Organizations.add_member(organization, member)

    {:ok, _} =
      MemberPermissions.update(
        organization,
        owner,
        member,
        ~w(project:read translation:read analytics:read toki:read toki:write)
      )

    {:ok, project} = Projects.create_project(account, %{handle: "app", name: "App"})
    project = Repo.preload(project, :account)
    {:ok, detail} = Toki.create_conversation(owner, project, %{"id" => Ecto.UUID.generate()})
    refute Glossia.Authz.authorize?(:toki_read, member, detail.conversation)
    refute Glossia.Authz.authorize?(:toki_write, member, detail.conversation)

    auth = TestHelpers.authenticate(conn, member, @scopes)
    assert auth |> get(conversation_path(project, detail.conversation.id)) |> json_response(404)

    assert submit(auth, message_path(project, detail.conversation.id), %{
             id: Ecto.UUID.generate(),
             content: "Steal"
           })
           |> json_response(404)

    assert auth
           |> post(conversations_path(project), %{id: detail.conversation.id})
           |> json_response(409)

    {:ok, own} = Toki.create_conversation(member, project, %{"id" => Ecto.UUID.generate()})
    refute Glossia.Authz.authorize?(:toki_read, owner, own.conversation)

    assert conn
           |> TestHelpers.authenticate(owner, @scopes)
           |> get(conversation_path(project, own.conversation.id))
           |> json_response(404)

    {:ok, _} =
      MemberPermissions.update(
        organization,
        owner,
        member,
        ~w(toki:read toki:write analytics:read translation:read)
      )

    # Even a dedicated grant cannot bypass the separate project visibility gate.
    assert auth |> get(conversations_path(project)) |> json_response(403)
  end

  test "messages queue without model inference in the request, replay enqueues only once",
       context do
    %{conn: conn, owner: owner, project: project} = context
    {:ok, detail} = Toki.create_conversation(owner, project, %{"id" => Ecto.UUID.generate()})
    auth = TestHelpers.authenticate(conn, owner, @scopes)
    path = message_path(project, detail.conversation.id)
    id = Ecto.UUID.generate()

    body =
      submit(auth, path, %{id: id, content: "What should I translate?"}) |> json_response(202)

    assert body["conversation"]["status"] == "queued"
    assert [%{"id" => ^id, "role" => "user"}] = body["messages"]

    assert submit(auth, path, %{id: id, content: "What should I translate?"})
           |> json_response(202) == body

    assert [%Oban.Job{args: %{"message_id" => ^id}}] = all_enqueued(worker: ReplyWorker)
    assert Repo.aggregate(Message, :count) == 1
    assert submit(auth, path, %{id: id, content: "Changed"}) |> json_response(409)

    assert submit(auth, path, %{id: Ecto.UUID.generate(), content: "Second"})
           |> json_response(409)

    {:ok, other} = Toki.create_conversation(owner, project, %{"id" => Ecto.UUID.generate()})

    assert submit(auth, message_path(project, other.conversation.id), %{
             id: id,
             content: "What should I translate?"
           })
           |> json_response(409)
  end

  test "messages validate UUIDs, blanks, types, size and prevent role or owner injection",
       context do
    %{conn: conn, owner: owner, project: project} = context
    {:ok, detail} = Toki.create_conversation(owner, project, %{"id" => Ecto.UUID.generate()})
    auth = TestHelpers.authenticate(conn, owner, @scopes)
    path = message_path(project, detail.conversation.id)

    for attrs <- [
          %{content: "Missing ID"},
          %{id: "bad", content: "Hi"},
          %{id: Ecto.UUID.generate()},
          %{id: Ecto.UUID.generate(), content: "  "},
          %{id: Ecto.UUID.generate(), content: 123},
          %{id: Ecto.UUID.generate(), content: String.duplicate("x", 8_001)}
        ] do
      assert submit(auth, path, attrs) |> json_response(422)
    end

    assert all_enqueued(worker: ReplyWorker) == []

    body =
      submit(auth, path, %{
        id: Ecto.UUID.generate(),
        content: "Hi",
        role: "assistant",
        status: "completed",
        user_id: context.outsider.id
      })
      |> json_response(202)

    assert [%{"role" => "user"}] = body["messages"]
    assert body["conversation"]["status"] == "queued"
  end

  test "worker uses resolved credentials, bounded HTTP and persists a single provider response",
       context do
    %{conn: conn, owner: owner, project: project} = context

    {:ok, _} =
      Glossia.LLMModels.create_model(owner.account, owner, %{
        handle: "toki",
        model: "openai/gpt-4o-mini",
        api_key: "test-key",
        base_url: "https://inference.test/v1",
        default: true
      })

    {:ok, detail} = Toki.create_conversation(owner, project, %{"id" => Ecto.UUID.generate()})
    auth = TestHelpers.authenticate(conn, owner, @scopes)
    id = Ecto.UUID.generate()

    submit(auth, message_path(project, detail.conversation.id), %{id: id, content: "Hello Toki"})
    |> json_response(202)

    expect(Req, :request, fn request ->
      assert request.options[:api_key] == "test-key"
      assert request.options[:base_url] == "https://inference.test/v1"
      assert request.options[:model] == "gpt-4o-mini"
      refute request.options[:tools]
      assert request.options[:retry] == false
      assert request.options[:max_retries] == 0
      assert request.options[:redirect] == false
      assert request.options[:max_tokens] == 2_048
      assert request.options[:receive_timeout] == 60_000
      assert request.options[:pool_timeout] == 5_000
      assert request.options[:connect_options] == [timeout: 5_000]

      [
        %{role: :system, content: [%{text: prompt}]},
        %{role: :user, content: [%{text: transcript}]}
      ] = request.options.context.messages

      assert prompt =~ "read-only"
      assert [%{"role" => "user", "content" => "Hello Toki"}] = JSON.decode!(transcript)

      {:ok,
       %Req.Response{
         status: 200,
         body: %ReqLLM.Response{
           id: "provider-response",
           model: "openai:gpt-4o-mini",
           context: request.options.context,
           message: ReqLLM.Context.assistant("How can I help with localization?")
         }
       }}
    end)

    [job] = all_enqueued(worker: ReplyWorker)
    assert :ok = ReplyWorker.perform(job)
    assert :ok = ReplyWorker.perform(job)
    body = auth |> get(conversation_path(project, detail.conversation.id)) |> json_response(200)
    assert body["conversation"]["status"] == "completed"

    assert [
             %{"role" => "user", "id" => ^id},
             %{"role" => "assistant", "content" => "How can I help with localization?"}
           ] = body["messages"]

    assert submit(auth, message_path(project, detail.conversation.id), %{
             id: id,
             content: "Hello Toki"
           })
           |> json_response(200) == body

    assert length(all_enqueued(worker: ReplyWorker)) == 1
  end

  test "unavailable providers fail clearly without fabricated assistant messages", context do
    %{conn: conn, owner: owner, project: project} = context
    {:ok, detail} = Toki.create_conversation(owner, project, %{"id" => Ecto.UUID.generate()})
    auth = TestHelpers.authenticate(conn, owner, @scopes)

    submit(auth, message_path(project, detail.conversation.id), %{
      id: Ecto.UUID.generate(),
      content: "Hello"
    })
    |> json_response(202)

    [job] = all_enqueued(worker: ReplyWorker)
    assert :ok = ReplyWorker.perform(job)
    body = auth |> get(conversation_path(project, detail.conversation.id)) |> json_response(200)
    assert body["conversation"]["status"] == "failed"
    assert body["conversation"]["error"] == "provider_unavailable"
    assert [%{"role" => "user"}] = body["messages"]
  end

  test "membership permissions constrain every dedicated capability even with token scopes",
       context do
    %{owner: owner, outsider: member, conn: conn} = context

    {:ok, %{organization: organization, account: account}} =
      Organizations.create_organization(owner, %{
        handle: "limited-#{System.unique_integer([:positive])}"
      })

    {:ok, _} = Organizations.add_member(organization, member)
    {:ok, _} = MemberPermissions.update(organization, owner, member, ["project:read"])
    {:ok, project} = Projects.create_project(account, %{handle: "app", name: "Application"})
    project = Repo.preload(project, :account)
    auth = TestHelpers.authenticate(conn, member, @scopes)

    for path <- [
          ~p"/api/#{account.handle}/projects/#{project.handle}/translations",
          ~p"/api/#{account.handle}/projects/#{project.handle}/analytics",
          conversations_path(project)
        ] do
      assert auth |> get(path) |> json_response(403)
    end

    assert auth
           |> post(conversations_path(project), %{id: Ecto.UUID.generate()})
           |> json_response(403)
  end

  test "revoked project access is rechecked before background inference", context do
    %{owner: owner, outsider: member, conn: conn} = context

    {:ok, %{organization: organization, account: account}} =
      Organizations.create_organization(owner, %{
        handle: "revoke-#{System.unique_integer([:positive])}"
      })

    {:ok, _} = Organizations.add_member(organization, member)
    {:ok, project} = Projects.create_project(account, %{handle: "private", name: "Private"})
    project = Repo.preload(project, :account)
    {:ok, detail} = Toki.create_conversation(member, project, %{"id" => Ecto.UUID.generate()})
    auth = TestHelpers.authenticate(conn, member, @scopes)

    submit(auth, message_path(project, detail.conversation.id), %{
      id: Ecto.UUID.generate(),
      content: "Hello"
    })
    |> json_response(202)

    {:ok, _} = MemberPermissions.update(organization, owner, member, [])
    [job] = all_enqueued(worker: ReplyWorker)
    assert :ok = ReplyWorker.perform(job)
    conversation = Repo.get!(Conversation, detail.conversation.id)
    assert conversation.status == "failed"
    assert conversation.error == "not_authorized"
    assert Repo.aggregate(Message, :count) == 1
  end

  defp conversations_path(project),
    do: ~p"/api/#{project.account.handle}/projects/#{project.handle}/toki/conversations"

  defp conversation_path(project, id),
    do: ~p"/api/#{project.account.handle}/projects/#{project.handle}/toki/conversations/#{id}"

  defp message_path(project, id),
    do:
      ~p"/api/#{project.account.handle}/projects/#{project.handle}/toki/conversations/#{id}/messages"

  defp submit(conn, path, attrs),
    do: with_testing_mode(:manual, fn -> post(conn, path, attrs) end)

  defp insert_event(project_id, at, pathname, country, visitor) do
    row = %Glossia.Analytics.Event{
      id: Ecto.UUID.generate(),
      project_id: project_id,
      visitor_id: visitor,
      session_id: "test",
      name: "pageview",
      hostname: "example.test",
      pathname: pathname,
      referrer: "",
      referrer_source: "",
      country_code: country,
      browser_language: "ja",
      served_locale: "en",
      has_locale_gap: 1,
      device: "desktop",
      browser: "Firefox",
      os: "Linux",
      screen_width: 1200,
      timezone: "UTC"
    }

    row = Map.from_struct(row) |> Map.delete(:__meta__) |> Map.put(:inserted_at, at)
    opts = Glossia.Analytics.Event.buffer_opts()
    types = Enum.zip(opts.fields, opts.types) ++ [inserted_at: :datetime]
    Glossia.IngestRepo.insert_all("analytics_events", [row], types: types)
  end
end
