defmodule GlossiaWeb.TranslationChannelTest do
  use GlossiaWeb.ConnCase, async: false
  use Mimic

  import Phoenix.ConnTest, except: [connect: 2, connect: 3]
  import Phoenix.ChannelTest

  alias Glossia.{
    MemberPermissions,
    Organizations,
    Projects,
    Repo,
    TestHelpers,
    TranslationSessions
  }

  alias Glossia.TranslationSessions.{Progress, ProgressEvent}
  alias GlossiaWeb.{NativeSocket, TranslationSnapshot}

  setup do
    unique = System.unique_integer([:positive])
    owner = TestHelpers.create_user("native-#{unique}@test.com", "native-#{unique}")
    outsider = TestHelpers.create_user("outside-#{unique}@test.com", "outside-#{unique}")
    {:ok, project} = Projects.create_project(owner.account, %{handle: "app", name: "App"})
    {:ok, other} = Projects.create_project(owner.account, %{handle: "other", name: "Other"})

    {:ok, session} =
      TranslationSessions.create_session(owner.account, project, %{
        commit_sha: "source-sha",
        source_language: "en",
        target_languages: ["es"]
      })

    token = token_for(owner)
    {:ok, socket} = connect(NativeSocket, %{}, connect_info: %{auth_token: token})

    %{
      owner: owner,
      outsider: outsider,
      project: project,
      other: other,
      session: session,
      token: token,
      socket: socket,
      payload: %{"organization" => owner.account.handle, "project" => project.handle}
    }
  end

  test "only a current bearer subprotocol credential connects and secrets are redacted", c do
    assert :error = connect(NativeSocket, %{})
    assert :error = connect(NativeSocket, %{token: c.token})
    assert :error = connect(NativeSocket, %{}, connect_info: %{auth_token: "unknown"})

    assert :error =
             connect(NativeSocket, %{auth_token: c.token}, connect_info: %{auth_token: c.token})

    refute inspect(c.socket) =~ c.token
    assert NativeSocket.id(c.socket) == "native:user:#{c.owner.id}"
  end

  test "join and HTTP return the same durable full projection, not private output", c do
    broadcast(c.session, %{type: "plan", total: 2, seq: 1})

    broadcast(c.session, %{
      type: "item_started",
      index: 0,
      output_path: "es/readme.md",
      locale: "es",
      seq: 2
    })

    broadcast(c.session, %{
      type: "item_completed",
      index: 0,
      output_preview: "PRIVATE OUTPUT",
      model_calls: 3,
      file_ref: "file-ref",
      seq: 3
    })

    assert {:ok, snapshot, joined} = join_translation(c)
    assert snapshot == TranslationSnapshot.detail(c.session)
    assert snapshot.progress.seq == 3
    assert %{done: 1, total: 2} = snapshot.progress.summary

    assert snapshot.progress.items == [
             %{
               index: 0,
               status: :done,
               output_path: "es/readme.md",
               locale: "es",
               turns: 3,
               file_ref: "file-ref"
             }
           ]

    refute JSON.encode!(snapshot) =~ "PRIVATE"

    body =
      c.conn
      |> put_req_header("authorization", "Bearer #{c.token}")
      |> get(
        ~p"/api/#{c.owner.account.handle}/projects/#{c.project.handle}/translations/#{c.session.id}"
      )
      |> json_response(200)

    assert body == JSON.decode!(JSON.encode!(snapshot))

    assert Registry.lookup(Glossia.PubSub, "translation_session:#{c.session.id}")
           |> Enum.any?(fn {pid, _} -> pid == joined.channel_pid end)
  end

  test "subscribe precedes snapshot read, and the live tail folds only once", c do
    broadcast(c.session, %{type: "plan", total: 1, seq: 1})
    progress = TranslationSessions.session_progress(c.session.id)
    set_mimic_global()

    stub(TranslationSessions, :session_progress, fn id ->
      assert id == c.session.id

      assert Enum.any?(Registry.lookup(Glossia.PubSub, "translation_session:#{id}"), fn {pid, _} ->
               pid == self()
             end)

      event = %{type: "item_skipped", seq: 2}
      broadcast(c.session, event)
      broadcast(c.session, event)
      progress
    end)

    assert {:ok, %{progress: %{seq: 1}}, _joined} = join_translation(c)
    assert_push "snapshot", %{progress: %{seq: 2, summary: %{skipped: 1}}}, 1_000
    refute_push "snapshot", _, 200
  end

  test "live events coalesce, fold public turns, and ignore output/thinking", c do
    {:ok, _, _joined} = join_translation(c)
    broadcast(c.session, %{type: "plan", total: 1, seq: 1})

    broadcast(c.session, %{
      type: "item_started",
      index: 0,
      locale: "es",
      output_path: "es/a",
      seq: 2
    })

    for seq <- 3..12 do
      broadcast(c.session, %{type: "item_event", index: 0, event: %{type: "turn_start"}, seq: seq})
    end

    for type <- ~w(text thinking private_provider_payload) do
      broadcast(c.session, %{
        type: "item_event",
        index: 0,
        event: %{type: type, text: String.duplicate("PRIVATE", 10_000)},
        seq: 20
      })
    end

    assert_push "snapshot", snapshot, 1_000
    assert %{seq: 2, summary: %{running: 1}, items: [%{turns: 10}]} = snapshot.progress
    refute JSON.encode!(snapshot) =~ "PRIVATE"
    refute_push "snapshot", _, 200

    broadcast(c.session, %{type: "item_completed", index: 0, model_calls: 10, seq: 21})
    assert_push "snapshot", %{progress: %{seq: 21, summary: %{done: 1}}}, 1_000
  end

  test "status and publication notifications refetch the authorized session", c do
    {:ok, _, _joined} = join_translation(c)

    session =
      Repo.update!(Ecto.Changeset.change(c.session, status: "completed", summary: "Ready"))

    TranslationSessions.broadcast_session_status(session, "completed")
    assert_push "snapshot", %{session: %{status: "completed", summary: "Ready"}}, 1_000

    assert {:ok, _} =
             TranslationSessions.update_session_publication(session, %{
               publication_branch: "translated"
             })

    assert_push "snapshot", snapshot, 1_000
    assert snapshot.session.status == "completed"
    refute Map.has_key?(snapshot.session, :publication_branch)
  end

  test "renewal repairs a durable event missed by PubSub", c do
    {:ok, _, joined} = join_translation(c)

    %ProgressEvent{}
    |> ProgressEvent.changeset(%{
      session_id: c.session.id,
      seq: 1,
      payload: %{"type" => "plan", "total" => 9, "seq" => 1}
    })
    |> Repo.insert!()

    send(joined.channel_pid, :renew)
    assert_push "snapshot", %{progress: %{seq: 1, summary: %{total: 9}}}, 1_000
  end

  test "cross-project, missing, malformed and missing project joins fail closed", c do
    for {id, payload} <- [
          {c.session.id, %{c.payload | "project" => c.other.handle}},
          {c.session.id, %{c.payload | "project" => "missing"}},
          {Ecto.UUID.generate(), c.payload},
          {"bad", c.payload}
        ] do
      assert {:error, %{reason: "not_found"}} =
               subscribe_and_join(c.socket, "translation:#{id}", payload)
    end

    assert {:error, %{reason: "not_found"}} =
             subscribe_and_join(c.socket, "translation:#{c.session.id}", %{})

    {:ok, outsider} =
      connect(NativeSocket, %{}, connect_info: %{auth_token: token_for(c.outsider)})

    assert {:error, %{reason: "forbidden"}} = join_translation(%{c | socket: outsider})
  end

  test "public translation reads retain HTTP semantics without a project token scope", c do
    Repo.update!(Ecto.Changeset.change(c.owner.account, visibility: "public"))

    {:ok, outsider} =
      connect(NativeSocket, %{}, connect_info: %{auth_token: token_for(c.outsider)})

    assert {:ok, _, _} = join_translation(%{c | socket: outsider})
  end

  test "the current grant is rechecked on join, even after a successful connect", c do
    grant = Repo.get_by!(Boruta.Ecto.Token, value: c.token)

    for changes <- [
          [scope: "user:read"],
          [revoked_at: DateTime.utc_now()],
          [expires_at: DateTime.utc_now() |> DateTime.to_unix()]
        ] do
      grant |> Ecto.Changeset.change(changes) |> Repo.update!()
      reason = if Keyword.has_key?(changes, :scope), do: "forbidden", else: "sign_in_required"
      assert {:error, %{reason: ^reason}} = join_translation(c)

      Repo.update!(
        Ecto.Changeset.change(Repo.get!(Boruta.Ecto.Token, grant.id),
          scope: "translation:read",
          revoked_at: nil,
          expires_at: DateTime.to_unix(DateTime.utc_now()) + 3600
        )
      )
    end
  end

  test "grant scope revocation between event and flush denies before sending a snapshot", c do
    assert Boruta.Config.access_tokens().get_by(value: c.token).scope == "translation:read"
    {:ok, _, joined} = join_translation(c)
    monitor = Process.monitor(joined.channel_pid)
    broadcast(c.session, %{type: "plan", total: 1, seq: 1})
    grant = Repo.get_by!(Boruta.Ecto.Token, value: c.token)
    Repo.update!(Ecto.Changeset.change(grant, scope: "user:read"))
    assert_push "access_revoked", %{reason: "forbidden"}, 1_000
    assert_receive {:DOWN, ^monitor, :process, _, :normal}
    refute_push "snapshot", _, 200
  end

  test "a missing current user invalidates authentication, not only membership", c do
    {:ok, _, joined} = join_translation(c)
    grant = Repo.get_by!(Boruta.Ecto.Token, value: c.token)
    Repo.update!(Ecto.Changeset.change(grant, sub: Ecto.UUID.generate()))
    send(joined.channel_pid, :renew)
    assert_push "access_revoked", %{reason: "sign_in_required"}, 1_000
    refute_push "snapshot", _, 100

    Repo.update!(Ecto.Changeset.change(Repo.get!(Boruta.Ecto.Token, grant.id), sub: "bad"))
    assert :error = connect(NativeSocket, %{}, connect_info: %{auth_token: c.token})
  end

  test "revocation during a durable read is rechecked before its snapshot can escape", c do
    {:ok, _, joined} = join_translation(c)
    grant = Repo.get_by!(Boruta.Ecto.Token, value: c.token)
    set_mimic_global()

    stub(TranslationSessions, :session_progress, fn _id ->
      Repo.update!(Ecto.Changeset.change(grant, revoked_at: DateTime.utc_now()))
      Progress.fold([%{type: "plan", total: 99, seq: 1}])
    end)

    send(joined.channel_pid, :renew)
    assert_push "access_revoked", %{reason: "sign_in_required"}, 1_000
    refute_push "snapshot", _, 100
  end

  test "revoked and expired grants fail renewal with sign_in_required", c do
    for changes <- [
          [revoked_at: DateTime.utc_now()],
          [expires_at: DateTime.utc_now() |> DateTime.to_unix()]
        ] do
      token = token_for(c.owner)
      {:ok, socket} = connect(NativeSocket, %{}, connect_info: %{auth_token: token})
      {:ok, _, joined} = join_translation(%{c | socket: socket})
      grant = Repo.get_by!(Boruta.Ecto.Token, value: token)
      Repo.update!(Ecto.Changeset.change(grant, changes))
      send(joined.channel_pid, :renew)
      assert_push "access_revoked", %{reason: "sign_in_required"}, 1_000
      refute_push "snapshot", _, 100
    end
  end

  test "idle sockets reauthorize on their real five-second lease", c do
    {:ok, _, _joined} = join_translation(c)
    grant = Repo.get_by!(Boruta.Ecto.Token, value: c.token)
    Repo.update!(Ecto.Changeset.change(grant, revoked_at: DateTime.utc_now()))
    assert_push "access_revoked", %{reason: "sign_in_required"}, 6_000
    refute_push "snapshot", _, 100
  end

  test "member permissions and membership removal are observed before every push", c do
    for revoke <- [:permissions, :membership] do
      {:ok, %{organization: organization, account: account}} =
        Organizations.create_organization(c.owner, %{
          handle: "native-org-#{System.unique_integer([:positive])}"
        })

      {:ok, _} = Organizations.add_member(organization, c.outsider)

      {:ok, _} =
        MemberPermissions.update(
          organization,
          c.owner,
          c.outsider,
          ~w(project:read translation:read)
        )

      {:ok, project} = Projects.create_project(account, %{handle: "app", name: "App"})
      {:ok, session} = TranslationSessions.create_session(account, project, %{})

      {:ok, socket} =
        connect(NativeSocket, %{}, connect_info: %{auth_token: token_for(c.outsider)})

      payload = %{"organization" => account.handle, "project" => project.handle}

      {:ok, _, _joined} =
        join_translation(%{c | socket: socket, session: session, payload: payload})

      case revoke do
        :permissions ->
          MemberPermissions.update(organization, c.owner, c.outsider, ["project:read"])

        :membership ->
          Organizations.remove_member(organization, c.outsider)
      end

      broadcast(session, %{type: "plan", total: 1, seq: 1})
      assert_push "access_revoked", %{reason: "forbidden"}, 1_000
      refute_push "snapshot", _, 100
    end
  end

  test "a deleted or moved session stops the subscription without exposing its new data", c do
    {:ok, _, joined} = join_translation(c)
    Repo.update!(Ecto.Changeset.change(c.session, project_id: c.other.id, summary: "FOREIGN"))
    send(joined.channel_pid, :renew)
    assert_push "access_revoked", %{reason: "not_found"}, 1_000
    refute_push "snapshot", _, 100
  end

  test "projection caps rows and bytes but counts all files, with no output or reasoning", c do
    progress =
      Enum.reduce(0..599, Progress.new(), fn index, state ->
        Progress.apply_event(state, %{
          type: "item_started",
          index: index,
          output_path: "es/#{index}",
          locale: "es"
        })
      end)

    snapshot = TranslationSnapshot.project(c.session, progress, 42)
    assert length(snapshot.progress.items) == 500
    assert snapshot.progress.omitted_items == 100
    assert snapshot.progress.summary.running == 600
    assert {:ok, _} = TranslationSnapshot.bounded(snapshot)

    large =
      Progress.apply_event(progress, %{
        type: "item_started",
        index: 0,
        output_path: String.duplicate("x", 600_000)
      })

    snapshot = TranslationSnapshot.project(c.session, large, 42)
    assert snapshot.progress.omitted_items == 101
    assert byte_size(JSON.encode!(snapshot)) < 1_000_000

    huge_session = %{c.session | summary: String.duplicate("x", 1_000_001)}

    assert {:error, "payload_too_large"} =
             huge_session |> TranslationSnapshot.detail() |> TranslationSnapshot.bounded()
  end

  test "oversized session metadata is never sent over the channel", c do
    {:ok, _, joined} = join_translation(c)

    Repo.update!(
      Ecto.Changeset.change(c.session,
        target_languages: List.duplicate(String.duplicate("x", 255), 5_000)
      )
    )

    send(joined.channel_pid, :renew)
    assert_push "error", %{reason: "payload_too_large"}, 1_000
    refute_push "snapshot", _, 100
    assert {:error, %{reason: "payload_too_large"}} = join_translation(c)
  end

  test "the real endpoint upgrades the bearer subprotocol and rejects a missing credential", c do
    server = start_supervised!({Bandit, plug: GlossiaWeb.Endpoint, port: 0, ip: {127, 0, 0, 1}})
    {:ok, {_address, port}} = ThousandIsland.listener_info(server)
    protocol = "phoenix,base64url.bearer.phx.#{Base.url_encode64(c.token, padding: false)}"
    response = upgrade(port, protocol)
    assert response =~ "101 Switching Protocols"
    assert String.downcase(response) =~ "sec-websocket-protocol: phoenix"
    assert upgrade(port, "phoenix") =~ "403 Forbidden"

    assert upgrade(port, protocol, "/native/socket/websocket?vsn=2.0.0&auth_token=not-allowed") =~
             "403 Forbidden"
  end

  defp token_for(user, scopes \\ ["translation:read"]) do
    conn = TestHelpers.authenticate(Phoenix.ConnTest.build_conn(), user, scopes)
    ["Bearer " <> token] = get_req_header(conn, "authorization")
    token
  end

  defp join_translation(c),
    do: subscribe_and_join(c.socket, "translation:#{c.session.id}", c.payload)

  defp broadcast(session, event), do: TranslationSessions.broadcast_session_event(session, event)

  defp upgrade(port, protocol, path \\ "/native/socket/websocket?vsn=2.0.0") do
    {:ok, connection} = :gen_tcp.connect({127, 0, 0, 1}, port, [:binary, active: false], 5_000)

    :ok =
      :gen_tcp.send(connection, [
        "GET ",
        path,
        " HTTP/1.1\r\n",
        "Host: localhost\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n",
        "Sec-WebSocket-Version: 13\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n",
        "Sec-WebSocket-Protocol: ",
        protocol,
        "\r\n\r\n"
      ])

    {:ok, response} = :gen_tcp.recv(connection, 0, 5_000)
    :gen_tcp.close(connection)
    response
  end
end
