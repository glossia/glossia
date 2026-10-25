defmodule Glossia.PushTest do
  use GlossiaWeb.ConnCase, async: false
  use Mimic
  use Oban.Testing, repo: Glossia.Repo
  import Ecto.Query
  import Ecto.Changeset, only: [change: 2]

  alias Boruta.Ecto.{Client, Token}
  alias Glossia.{AccountTokens, Projects, Push, Repo, TestHelpers, TranslationSessions}
  alias Glossia.Push.{Config, Deliver, Installation}
  alias Glossia.Toki.{Conversation, Message}

  @device %{
    "platform" => "ios",
    "environment" => "production",
    "token" => String.duplicate("ab", 32)
  }

  setup :set_mimic_global

  setup do
    previous = Application.get_env(:glossia, Push)

    on_exit(fn ->
      if previous,
        do: Application.put_env(:glossia, Push, previous),
        else: Application.delete_env(:glossia, Push)
    end)

    {_, pem} = JOSE.JWK.generate_key({:ec, "P-256"}) |> JOSE.JWK.to_pem()

    config =
      Config.parse!(%{
        "GLOSSIA_APNS_TEAM_ID" => "ABCDEFGHIJ",
        "GLOSSIA_APNS_KEY_ID" => "1234567890",
        "GLOSSIA_APNS_PRIVATE_KEY" => pem,
        "GLOSSIA_APNS_TOPIC" => "ai.glossia.mobile"
      })

    cache = :"push_credentials_#{System.unique_integer([:positive])}"
    start_supervised!({Glossia.Push.Credentials, name: cache})
    Application.put_env(:glossia, Push, Keyword.put(config, :credentials_cache, cache))
    stub(GlossiaWeb.Endpoint, :url, fn -> "https://glossia.example" end)
    stub(Req, :post, fn _, _ -> flunk("unexpected push transport") end)

    unique = System.unique_integer([:positive])
    user = TestHelpers.create_user("push-#{unique}@example.test", "push")
    outsider = TestHelpers.create_user("push-other-#{unique}@example.test", "push-other")
    {:ok, user} = Glossia.Accounts.update_user_fluent_languages(user, ["es"])
    {:ok, outsider} = Glossia.Accounts.update_user_fluent_languages(outsider, ["es-MX"])
    {:ok, project} = Projects.create_project(user.account, %{handle: "app", name: "App"})
    project = Repo.preload(project, :account)
    client = client()
    token = token(user, client)
    conversation = Repo.insert!(%Conversation{user_id: user.id, project_id: project.id})

    message =
      Repo.insert!(%Message{
        conversation_id: conversation.id,
        role: "user",
        status: "completed",
        content: "Private prompt"
      })

    reply =
      Repo.insert!(%Message{
        conversation_id: conversation.id,
        reply_to_id: message.id,
        role: "assistant",
        status: "completed",
        content: "Private reply"
      })

    %{
      user: user,
      outsider: outsider,
      project: project,
      client: client,
      token: token,
      conversation: conversation,
      message: message,
      reply: reply,
      cache: cache,
      id: Ecto.UUID.generate()
    }
  end

  test "bearer-only enrollment derives owner and OAuth client, rejecting account tokens, other clients and extra fields",
       c do
    assert request(:update, c.id, nil, @device).status == 401

    {:ok, %{plain_token: account_token}} =
      AccountTokens.create_account_token(c.user.account, c.user, %{
        "name" => "Push",
        "scope" => "user:read"
      })

    assert request(:update, c.id, account_token, @device).status == 403
    other_client = client(%{redirect_uris: ["https://other.example/callback"]})
    other_token = token(c.user, other_client)
    assert request(:update, c.id, other_token.value, @device).status == 403

    for attrs <- [
          Map.put(@device, "user_id", c.outsider.id),
          Map.put(@device, "topic", "other"),
          Map.delete(@device, "environment"),
          %{@device | "token" => "invalid"},
          %{@device | "environment" => "both"}
        ] do
      assert request(:update, c.id, c.token.value, attrs).status == 400
    end

    Logger.put_process_level(self(), :debug)

    log =
      ExUnit.CaptureLog.capture_log([level: :debug], fn ->
        response = request(:update, c.id, c.token.value, @device)
        assert json_response(response, 200) == %{"registered" => true, "registration_id" => c.id}
        assert get_resp_header(response, "cache-control") == ["no-store"]
      end)

    Logger.delete_process_level(self())
    refute log =~ @device["token"]
    assert Sentry.Context.get_all().request.data["token"] == "[FILTERED]"
    assert Sentry.Context.get_all().request.data["platform"] == @device["platform"]
    response = request(:update, c.id, c.token.value, @device)
    assert json_response(response, 200) == %{"registered" => true, "registration_id" => c.id}
    assert get_resp_header(response, "cache-control") == ["no-store"]
    installation = Repo.get!(Installation, c.id)
    assert installation.user_id == c.user.id
    assert installation.oauth_client_id == c.client.id
    assert installation.token == @device["token"]

    [raw] =
      Repo.query!("SELECT token FROM push_installations WHERE id = $1", [Ecto.UUID.dump!(c.id)],
        log: false
      ).rows

    refute hd(raw) == @device["token"]
    refute inspect(installation) =~ @device["token"]
  end

  test "unknown DELETE is idempotent and fences a delayed PUT forever", c do
    assert request(:delete, c.id, c.token.value).status == 200
    assert request(:delete, c.id, c.token.value).status == 200

    assert json_response(request(:update, c.id, c.token.value, @device), 409)["error"] ==
             "installation_retired"

    tombstone = Repo.get!(Installation, c.id)
    assert tombstone.retired_at
    assert is_nil(tombstone.user_id) and is_nil(tombstone.token)
    assert :ok = Push.prune()
    assert Repo.get!(Installation, c.id)
  end

  test "ownership cannot move; unrelated clients cannot delete; same-installation next user can clean up",
       c do
    assert request(:update, c.id, c.token.value, @device).status == 200
    outsider_client = client()
    outsider_token = token(c.outsider, outsider_client)
    assert request(:delete, c.id, outsider_token.value).status == 200
    refute Repo.get!(Installation, c.id).retired_at
    other_device = %{@device | "token" => String.duplicate("cd", 32)}
    assert request(:update, c.id, outsider_token.value, other_device).status == 409
    refute Repo.get!(Installation, c.id).retired_at
    next_token = token(c.outsider, c.client)
    assert request(:update, c.id, next_token.value, other_device).status == 409
    assert Repo.get!(Installation, c.id).retired_at
    assert request(:update, c.id, c.token.value, @device).status == 409
  end

  test "token transfer retires old jobs and rotation survives a delayed provider invalidation",
       c do
    register!(c)
    old = Repo.get!(Installation, c.id)
    rotated = %{@device | "token" => String.duplicate("cd", 32)}
    assert request(:update, c.id, c.token.value, rotated).status == 200
    assert :kept = Push.retire_invalidated(old)
    assert Repo.get!(Installation, c.id).token == rotated["token"]
    fresh = Repo.get!(Installation, c.id)

    assert :kept =
             Push.retire_invalidated(fresh,
               unregistered_at: DateTime.add(fresh.last_registered_at, -1)
             )

    job = enqueue!(c)
    new_id = Ecto.UUID.generate()
    assert request(:update, new_id, c.token.value, rotated).status == 200
    assert Repo.get!(Installation, c.id).retired_at
    assert {:cancel, :notification_unavailable} = Deliver.perform(job)
    assert Repo.get!(Installation, new_id).token == rotated["token"]
  end

  test "completed user turn is exact, private and source-bound; jobs hold no prompts, replies or tokens",
       c do
    register!(c)

    for source <- [
          %{conversation_id: c.conversation.id, message_id: c.reply.id},
          %{conversation_id: Ecto.UUID.generate(), message_id: c.message.id},
          %{conversation_id: c.conversation.id, message_id: Ecto.UUID.generate()},
          %{conversation_id: c.conversation.id, message_id: c.message.id, text: "injected"}
        ] do
      assert {:error, :invalid_notification} =
               Push.notify_user(c.user.id, "toki_completed", source)
    end

    assert {:error, :invalid_notification} =
             Push.notify_user(c.outsider.id, "toki_completed", source(c))

    Repo.update!(change(c.message, status: "failed"))

    assert {:error, :invalid_notification} =
             Push.notify_user(c.user.id, "toki_completed", source(c))

    Repo.update!(change(Repo.get!(Message, c.message.id), status: "completed"))
    job = enqueue!(c)
    refute inspect(job.args) =~ @device["token"]
    refute inspect(job.args) =~ "Private"
    assert job.args["source"]["message_id"] == c.message.id

    expect(Req, :post, fn url, opts ->
      assert URI.parse(url).host == "api.push.apple.com"
      assert opts[:finch] == Glossia.Push.Finch
      assert opts[:retry] == false and opts[:redirect] == false
      assert {"apns-topic", "ai.glossia.mobile"} in opts[:headers]
      payload = opts[:json]
      assert payload["v"] == "1"
      assert payload["registration_id"] == c.id

      assert payload["aps"]["alert"] == %{
               "title" => "Glossia",
               "body" => "You have an update in Glossia."
             }

      uri = URI.parse(payload["url"])
      assert uri.scheme == "glossia" and uri.host == "navigate"
      assert uri.path == "/#{c.user.account.handle}/#{c.project.handle}/toki/#{c.conversation.id}"
      assert URI.decode_query(uri.query) == %{"server" => "https://glossia.example"}
      refute inspect(payload) =~ "Private"
      {:ok, %Req.Response{status: 200}}
    end)

    assert :ok = Deliver.perform(job)
  end

  test "expired and revoked grants, changed scopes, deleted source and logged-out devices cancel public intents",
       c do
    register!(c)
    job = enqueue!(c)

    expired =
      put_in(
        job.args["expires_at"],
        DateTime.add(DateTime.utc_now(), -1) |> DateTime.to_iso8601()
      )

    assert {:cancel, :notification_unavailable} = Deliver.perform(expired)
    Repo.update!(change(c.token, refresh_token_revoked_at: DateTime.utc_now()))
    assert {:cancel, :notification_unavailable} = Deliver.perform(job)

    Repo.update!(
      change(Repo.get!(Token, c.token.id), refresh_token_revoked_at: nil, scope: "user:read")
    )

    assert {:cancel, :notification_unavailable} = Deliver.perform(job)

    Repo.update!(
      change(Repo.get!(Token, c.token.id),
        scope: "toki:read translation:read",
        inserted_at: DateTime.add(DateTime.utc_now(), -100_000_000)
      )
    )

    assert {:cancel, :notification_unavailable} = Deliver.perform(job)
    Repo.update!(change(c.token, inserted_at: DateTime.utc_now()))
    Repo.delete!(c.reply)
    assert {:cancel, :notification_unavailable} = Deliver.perform(job)
    assert request(:delete, c.id, c.token.value).status == 200
    assert {:cancel, :notification_unavailable} = Deliver.perform(job)
  end

  test "a normal refresh rotation preserves background delivery after access-token expiry", c do
    register!(c)
    job = enqueue!(c)
    Repo.update!(change(c.token, expires_at: 1, refresh_token_revoked_at: DateTime.utc_now()))
    token(c.user, c.client)
    expect(Req, :post, fn _, _ -> {:ok, %Req.Response{status: 200}} end)
    assert :ok = Deliver.perform(job)
  end

  test "source-linked Toki loses visibility when current translation scope or source disappears",
       c do
    {:ok, session} =
      TranslationSessions.create_session(c.user.account, c.project, %{status: "completed"})

    Repo.update!(change(c.conversation, translation_session_id: session.id))
    register!(c)
    job = enqueue!(c)
    Repo.update!(change(c.token, scope: "toki:read"))
    assert {:cancel, :notification_unavailable} = Deliver.perform(job)
    Repo.update!(change(Repo.get!(Token, c.token.id), scope: "toki:read translation:read"))
    Repo.delete!(session)
    assert {:cancel, :notification_unavailable} = Deliver.perform(job)
  end

  test "linguistic notifications recheck session-owned open reviews, not project-level reviews",
       c do
    {:ok, session} =
      TranslationSessions.create_session(c.user.account, c.project, %{status: "running"})

    {:ok, other} =
      TranslationSessions.create_session(c.user.account, c.project, %{status: "running"})

    review = review!(session)
    review!(other)
    register!(c)
    source = %{translation_session_id: session.id}

    Oban.Testing.with_testing_mode(:manual, fn ->
      assert {:ok, %{status: "awaiting_input"}} = Glossia.LinguisticReviews.pause(session.id)
    end)

    [job] = all_enqueued(worker: Deliver)
    conversation = Repo.get_by!(Conversation, linguistic_review_id: review.id)

    expect(Req, :post, fn _, opts ->
      assert URI.parse(opts[:json]["url"]).path ==
               "/#{c.user.account.handle}/#{c.project.handle}/toki/#{conversation.id}"

      {:ok, %Req.Response{status: 200}}
    end)

    assert :ok = Deliver.perform(job)
    {:ok, _} = Glossia.Accounts.update_user_fluent_languages(c.user, ["fr"])
    assert {:cancel, :notification_unavailable} = Deliver.perform(job)
    {:ok, _} = Glossia.Accounts.update_user_fluent_languages(c.user, ["es"])
    Repo.update!(change(review, status: "answered"))
    assert {:cancel, :notification_unavailable} = Deliver.perform(job)

    assert {:error, :invalid_notification} =
             Push.notify_user(c.user.id, "linguistic_input_needed", source)

    assert {:error, :invalid_notification} =
             Push.notify_user(c.outsider.id, "linguistic_input_needed", %{
               translation_session_id: other.id
             })
  end

  test "a completed Toki turn queues one private notification and replay never queues another",
       c do
    register!(c)
    Repo.delete!(c.reply)
    message = Repo.update!(change(c.message, status: "running"))

    Oban.Testing.with_testing_mode(:manual, fn ->
      assert {:ok, _} = Glossia.Toki.finish(message, {:ok, "The answer"})
      assert {:error, :already_finished} = Glossia.Toki.finish(message, {:ok, "Late duplicate"})
      assert [job] = all_enqueued(worker: Deliver)

      assert job.args["source"] == %{
               "conversation_id" => c.conversation.id,
               "message_id" => message.id
             }

      refute inspect(job.args) =~ "The answer"
    end)
  end

  test "provider retry backpressure and attempt counts remain bounded, and disabling APNs leaves cleanup working",
       c do
    register!(c)
    job = enqueue!(c)

    stub(Req, :post, fn _, _ ->
      {:ok, %Req.Response{status: 429, headers: %{"retry-after" => ["30"]}}}
    end)

    assert {:snooze, 30} = Deliver.perform(%{job | attempt: 1})
    assert {:cancel, :attempts_exhausted} = Deliver.perform(%{job | attempt: 5})

    stub(Req, :post, fn _, _ ->
      {:ok, %Req.Response{status: 503, headers: %{"retry-after" => ["99999"]}}}
    end)

    assert {:cancel, :expired} = Deliver.perform(job)
    Application.put_env(:glossia, Push, [])
    assert Push.capabilities() == %{"ios" => false, "android" => false}
    assert request(:update, Ecto.UUID.generate(), c.token.value, @device).status == 503
    assert {:cancel, :notification_unavailable} = Deliver.perform(job)
    assert request(:delete, c.id, c.token.value).status == 200
  end

  test "60 day expiry and ten-registration bound clear tokens without resurrecting IDs", c do
    for n <- 1..11 do
      attrs = %{@device | "token" => Base.encode16(:crypto.hash(:sha256, to_string(n)))}
      assert request(:update, Ecto.UUID.generate(), c.token.value, attrs).status == 200
    end

    assert Repo.aggregate(from(i in Installation, where: is_nil(i.retired_at)), :count) == 10
    register!(c)
    job = enqueue!(c)

    Repo.get!(Installation, c.id)
    |> change(last_registered_at: DateTime.add(DateTime.utc_now(), -61, :day))
    |> Repo.update!()

    assert {:cancel, :notification_unavailable} = Deliver.perform(job)
    assert :ok = Push.prune()
    assert Repo.get!(Installation, c.id).retired_at
    assert is_nil(Repo.get!(Installation, c.id).token)
  end

  test "Android public intents use FCM and reauthorize after credential exchange", c do
    {_, pem} = JOSE.JWK.generate_key({:rsa, 2048}) |> JOSE.JWK.to_pem()

    config =
      Config.parse!(%{
        "GLOSSIA_FCM_SERVICE_ACCOUNT_JSON" =>
          JSON.encode!(%{
            "type" => "service_account",
            "project_id" => "glossia-test",
            "client_email" => "push@glossia-test.iam.gserviceaccount.com",
            "private_key" => pem
          })
      })

    Application.put_env(:glossia, Push, Keyword.put(config, :credentials_cache, c.cache))

    device = %{
      "platform" => "android",
      "environment" => "production",
      "token" => "android-device-token"
    }

    assert request(:update, c.id, c.token.value, device).status == 200
    assert request(:update, Ecto.UUID.generate(), c.token.value, @device).status == 503
    job = enqueue!(c)

    expect(Req, :post, fn "https://oauth2.googleapis.com/token", _ ->
      {:ok,
       %Req.Response{status: 200, body: %{"access_token" => "fcm-access", "expires_in" => 3600}}}
    end)

    expect(Req, :post, fn "https://fcm.googleapis.com/v1/projects/glossia-test/messages:send",
                          opts ->
      data = opts[:json]["message"]["data"]
      assert data["v"] == "1" and data["registration_id"] == c.id
      assert data["body"] == "You have an update in Glossia."
      refute inspect(data) =~ "Private"
      {:ok, %Req.Response{status: 200}}
    end)

    assert :ok = Deliver.perform(job)

    Glossia.Push.Credentials.invalidate(:fcm, config[:fcm], c.cache)

    expect(Req, :post, fn "https://oauth2.googleapis.com/token", _ ->
      Repo.get!(Token, c.token.id)
      |> change(refresh_token_revoked_at: DateTime.utc_now())
      |> Repo.update!()

      {:ok,
       %Req.Response{
         status: 200,
         body: %{"access_token" => "new-fcm-access", "expires_in" => 3600}
       }}
    end)

    assert {:cancel, :notification_unavailable} = Deliver.perform(job)
  end

  test "removing current project membership cancels already enqueued linguistic notifications",
       c do
    {:ok, %{organization: org, account: account}} =
      Glossia.Organizations.create_organization(c.user, %{
        handle: "push-org-#{System.unique_integer([:positive])}"
      })

    {:ok, _} = Glossia.Organizations.add_member(org, c.outsider)
    {:ok, project} = Projects.create_project(account, %{handle: "private", name: "Private"})
    {:ok, session} = TranslationSessions.create_session(account, project, %{status: "running"})
    review!(session)
    access = token(c.outsider, client())
    assert request(:update, c.id, access.value, @device).status == 200

    Oban.Testing.with_testing_mode(:manual, fn ->
      assert {:ok, 1} =
               Push.notify_user(c.outsider.id, :linguistic_input_needed, %{
                 translation_session_id: session.id
               })
    end)

    [job] = all_enqueued(worker: Deliver)
    expect(Req, :post, fn _, _ -> {:ok, %Req.Response{status: 200}} end)
    assert :ok = Deliver.perform(job)
    Glossia.Organizations.remove_member(org, c.outsider)
    assert {:cancel, :notification_unavailable} = Deliver.perform(job)
  end

  test "definitive provider rejection retires only the attempted registration and HTTP origins fail closed",
       c do
    register!(c)
    job = enqueue!(c)
    stub(GlossiaWeb.Endpoint, :url, fn -> "http://localhost:4000" end)
    assert {:cancel, :https_endpoint_required} = Deliver.perform(job)
    stub(GlossiaWeb.Endpoint, :url, fn -> "https://glossia.example" end)

    expect(Req, :post, fn _, _ ->
      {:ok, %Req.Response{status: 400, body: %{"reason" => "BadDeviceToken"}}}
    end)

    assert {:cancel, :token_invalidated} = Deliver.perform(job)
    assert is_nil(Repo.get!(Installation, c.id).token)
    assert request(:update, c.id, c.token.value, @device).status == 409
  end

  defp register!(c) do
    assert request(:update, c.id, c.token.value, @device).status == 200
  end

  defp source(c), do: %{conversation_id: c.conversation.id, message_id: c.message.id}

  defp enqueue!(c) do
    Oban.Testing.with_testing_mode(:manual, fn ->
      assert {:ok, count} = Push.notify_user(c.user.id, "toki_completed", source(c))
      assert count >= 1
    end)

    all_enqueued(worker: Deliver) |> Enum.find(&(&1.args["registration_id"] == c.id))
  end

  defp request(action, id, value, body \\ nil) do
    conn = build_conn() |> put_req_header("content-type", "application/json")
    conn = if value, do: put_req_header(conn, "authorization", "Bearer #{value}"), else: conn

    case action do
      :update -> put(conn, ~p"/api/me/push-devices/#{id}", body)
      :delete -> delete(conn, ~p"/api/me/push-devices/#{id}")
    end
  end

  defp client(overrides \\ %{}) do
    attrs =
      Map.merge(
        %{
          name: "Native push",
          redirect_uris: ["glossia://oauth/callback"],
          confidential: false,
          pkce: true,
          public_refresh_token: true,
          public_revoke: true,
          token_endpoint_auth_methods: [],
          access_token_ttl: 3600,
          authorization_code_ttl: 60,
          refresh_token_ttl: 86_400
        },
        overrides
      )

    %Client{} |> Client.create_changeset(attrs) |> Repo.insert!()
  end

  defp token(user, client) do
    %Token{}
    |> Token.changeset_with_refresh_token(%{
      client_id: client.id,
      sub: user.id,
      scope: "user:read toki:read translation:read",
      access_token_ttl: 3600
    })
    |> Repo.insert!()
  end

  defp review!(session) do
    {:ok, review} =
      Glossia.LinguisticReviews.request(
        session.id,
        %{
          source_path: "en.md",
          output_path: "es.md",
          locale: "es",
          context_targets: %{}
        },
        "fingerprint",
        %{
          reason: "ambiguity",
          question: "Private question",
          source: "private source",
          translation: "private target"
        }
      )

    review
  end
end
