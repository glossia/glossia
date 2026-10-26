defmodule Glossia.Toki.HostHarnessTest do
  use Glossia.DataCase, async: false
  use Mimic
  use Oban.Testing, repo: Glossia.Repo

  alias Glossia.{Projects, TestHelpers, Toki, TranslationSessions}
  alias Glossia.Toki.{Agent, Conversation, HostHarness, Message, RecoveryWorker, ReplyWorker}
  alias Glossia.Translations.Credentials

  setup_all do
    Mimic.copy(Credentials)
    :ok
  end

  setup do
    original_config = Application.get_env(:glossia, HostHarness, [])

    original_env =
      System.get_env() |> Map.take(~w(PATH CLAUDE_CODE_OAUTH_TOKEN TOKI_SERVER_SECRET))

    directory = Path.join(System.tmp_dir!(), "toki-cli-test-#{Ecto.UUID.generate()}")
    File.mkdir!(directory)
    cli = Path.join(directory, "claude")

    File.write!(cli, """
    #!/bin/sh
    if [ "$1" = "--version" ]; then printf '2.1.285 (Claude Code)'; exit; fi
    printf 'Stub Claude reply'
    """)

    File.chmod!(cli, 0o700)
    System.put_env("PATH", directory <> ":" <> System.get_env("PATH"))
    System.put_env("CLAUDE_CODE_OAUTH_TOKEN", "test-only-host-token")
    System.put_env("TOKI_SERVER_SECRET", "must-not-reach-cli")

    Application.put_env(
      :glossia,
      HostHarness,
      HostHarness.config(:dev, %{
        "GLOSSIA_TOKI_HARNESS" => "claude",
        "GLOSSIA_TOKI_HARNESS_MODEL" => "haiku"
      })
    )

    on_exit(fn ->
      Application.put_env(:glossia, HostHarness, original_config)

      for key <- ~w(PATH CLAUDE_CODE_OAUTH_TOKEN TOKI_SERVER_SECRET) do
        if value = original_env[key], do: System.put_env(key, value), else: System.delete_env(key)
      end

      File.rm_rf!(directory)
    end)

    unique = System.unique_integer([:positive])
    user = TestHelpers.create_user("toki-harness-#{unique}@example.test", "toki-harness")
    {:ok, project} = Projects.create_project(user.account, %{handle: "app", name: "Application"})
    project = Repo.preload(project, :account)
    {:ok, detail} = Toki.create_conversation(user, project, %{"id" => Ecto.UUID.generate()})
    %{user: user, project: project, conversation: detail.conversation, cli: cli}
  end

  test "only explicit dev configuration enables Claude; production and test ignore all harness env" do
    env = %{"GLOSSIA_TOKI_HARNESS" => "claude", "GLOSSIA_TOKI_HARNESS_MODEL" => "haiku"}
    assert HostHarness.config(:dev, env) == [harness: :claude, model: "haiku"]
    assert HostHarness.config(:dev, %{}) == []
    assert HostHarness.config(:prod, env) == []
    assert HostHarness.config(:test, env) == []

    for harness <- ~w(codex pi other) do
      assert_raise RuntimeError, ~r/supports only claude/, fn ->
        HostHarness.config(:dev, %{"GLOSSIA_TOKI_HARNESS" => harness})
      end

      assert HostHarness.config(:prod, %{"GLOSSIA_TOKI_HARNESS" => harness}) == []
    end
  end

  test "production selection still rejects local OAuth credentials instead of starting a harness",
       c do
    Application.put_env(
      :glossia,
      HostHarness,
      HostHarness.config(:prod, %{"GLOSSIA_TOKI_HARNESS" => "claude"})
    )

    expect(Credentials, :resolve, fn _, nil ->
      {:ok, %{model: "anthropic/claude-haiku-4-5", auth: {:oauth, "local-session"}}}
    end)

    stub(MuonTrap, :cmd, fn _, _, _ -> flunk("production must not launch a CLI") end)
    stub(Req, :request, fn _ -> flunk("OAuth must not become an API provider key") end)
    assert {:error, :provider_unavailable} = Agent.reply(c.user, c.project, [], :all)
  end

  test "host keychain credentials stay in the CLI environment and missing login fails closed",
       c do
    System.delete_env("CLAUDE_CODE_OAUTH_TOKEN")
    expect(Credentials, :claude_session, fn -> %{auth: {:oauth, "stub-keychain-token"}} end)

    expect(MuonTrap, :cmd, fn _, args, opts ->
      refute inspect(args) =~ "stub-keychain-token"
      assert Map.new(opts[:env])["CLAUDE_CODE_OAUTH_TOKEN"] == "stub-keychain-token"
      {"Authenticated host reply", 0}
    end)

    assert {:ok, "Authenticated host reply"} = Agent.reply(c.user, c.project, [], :all)
    expect(Credentials, :claude_session, fn -> nil end)
    assert {:error, :provider_unavailable} = Agent.reply(c.user, c.project, [], :all)
  end

  test "installed Condukt adapter receives bounded context, no tools, isolated home and no server secrets",
       c do
    {:ok, _} =
      TranslationSessions.create_session(c.project.account, c.project, %{
        summary: "PRIVATE SOURCE"
      })

    messages = for _ <- 1..20, do: %Message{role: "user", content: String.duplicate("x", 8_000)}
    parent = self()

    expect(MuonTrap, :cmd, fn "bash", ["-lc", _, "condukt-agent-runtime", command | args], opts ->
      assert command == Path.join(opts[:cd], "claude")
      assert option(args, "--model") == "haiku"
      assert option(args, "--permission-mode") == "dontAsk"
      assert option(args, "--tools") == ""
      assert option(args, "--setting-sources") == ""
      assert option(args, "--settings") == ~s({"disableAllHooks":true})
      assert option(args, "--mcp-config") == ~s({"mcpServers":{}})
      assert option(args, "--max-turns") == "1"
      assert "--no-session-persistence" in args
      assert "--strict-mcp-config" in args
      assert "--safe-mode" in args
      assert "--disable-slash-commands" in args
      refute "--dangerously-skip-permissions" in args
      refute "--resume" in args
      prompt = option(args, "--system-prompt")
      refute prompt =~ "PRIVATE SOURCE"
      refute prompt =~ "test-only-host-token"
      transcript = args |> List.last() |> JSON.decode!()
      assert length(transcript) == 10
      assert String.length(List.last(transcript)["content"]) == 8_000
      assert Enum.all?(Enum.drop(transcript, -1), &(String.length(&1["content"]) == 2_000))
      assert opts[:timeout] == 60_000
      cwd = opts[:cd]
      refute cwd == File.cwd!()
      assert File.ls!(cwd) == ["claude"]
      assert Bitwise.band(File.stat!(cwd).mode, 0o777) == 0o700
      env = Map.new(opts[:env])
      assert env["GLOSSIA_TOKI_CLAUDE_COMMAND"] == c.cli
      assert env["HOME"] == cwd
      assert env["CLAUDE_CONFIG_DIR"] == cwd
      assert env["TOKI_SERVER_SECRET"] == ""
      assert env["CLAUDE_CODE_OAUTH_TOKEN"] == "test-only-host-token"
      assert env["CLAUDE_CODE_MAX_RETRIES"] == "0"
      assert env["CLAUDE_CODE_NONSTREAMING_TIMEOUT_RETRIES"] == "0"
      assert env["CLAUDE_CODE_RETRY_WATCHDOG"] == "0"
      send(parent, {:cwd, cwd})
      {"Harness response\n", 0}
    end)

    assert {:ok, "Harness response"} = Agent.reply(c.user, c.project, messages, ["toki:write"])
    assert_receive {:cwd, cwd}
    refute File.exists?(cwd)
  end

  test "unauthorized projects and source scopes never reach the CLI", c do
    stub(MuonTrap, :cmd, fn _, _, _ -> flunk("unauthorized CLI invocation") end)
    stranger = TestHelpers.create_user("toki-stranger@example.test", "stranger")
    assert {:error, :unauthorized} = Agent.reply(stranger, c.project, [], :all)
    assert {:error, :insufficient_scope, "toki:write"} = Agent.reply(c.user, c.project, [], [])

    {:ok, source} = TranslationSessions.create_session(c.project.account, c.project, %{})

    {:ok, %{conversation: conversation}} =
      Toki.create_conversation(c.user, c.project, %{
        "id" => Ecto.UUID.generate(),
        "translation_session_id" => source.id
      })

    assert {:error, :insufficient_scope, "translation:read"} =
             Agent.reply(c.user, c.project, [], ["toki:write"], conversation.id)
  end

  test "one claimed turn uses the real stub CLI once; client harness fields cannot select its runtime",
       c do
    job = enqueue(c)
    parent = self()

    expect(MuonTrap, :cmd, fn command, args, opts ->
      send(parent, {:cwd, opts[:cd]})
      Mimic.call_original(MuonTrap, :cmd, [command, args, opts])
    end)

    assert :ok = ReplyWorker.perform(job)
    assert :ok = ReplyWorker.perform(job)
    assert_receive {:cwd, cwd}
    refute File.exists?(cwd)
    assert Repo.get!(Conversation, c.conversation.id).status == "completed"

    assert Repo.one!(from m in Message, where: m.role == "assistant").content ==
             "Stub Claude reply"
  end

  test "old or unknown CLI versions cannot infer with unsupported retry controls", c do
    for version <- ["2.1.284 (Claude Code)", "unknown"] do
      File.write!(c.cli, """
      #!/bin/sh
      if [ "$1" = "--version" ]; then printf '#{version}'; exit; fi
      touch '#{c.cli}.inference'
      printf 'Must not infer'
      """)

      job = enqueue(c)

      expect(MuonTrap, :cmd, fn command, args, opts ->
        Mimic.call_original(MuonTrap, :cmd, [command, args, opts])
      end)

      assert :ok = ReplyWorker.perform(job)
      assert Repo.get!(Conversation, c.conversation.id).status == "failed"
      refute File.exists?(c.cli <> ".inference")
      assert :ok = ReplyWorker.perform(job)
    end
  end

  test "authorization lost during CLI inference discards the reply", c do
    other = TestHelpers.create_user("toki-new-owner@example.test", "new-owner")
    job = enqueue(c)

    expect(MuonTrap, :cmd, fn _, _, _ ->
      c.project |> Ecto.Changeset.change(account_id: other.account.id) |> Repo.update!()
      {"Reply generated before revocation", 0}
    end)

    assert :ok = ReplyWorker.perform(job)
    assert Repo.get!(Conversation, c.conversation.id).error == "not_authorized"
    assert Repo.aggregate(Message, :count) == 1
    assert :ok = ReplyWorker.perform(job)
  end

  test "CLI failures and invalid replies fail without fallback or another launch", c do
    for {output, status} <- [
          {"", 0},
          {String.duplicate("x", 8_001), 0},
          {String.duplicate("e\u0301\u0301", 8_000), 0},
          {"failed", 1}
        ] do
      job = enqueue(c)
      expect(MuonTrap, :cmd, fn _, _, _ -> {output, status} end)
      assert :ok = ReplyWorker.perform(job)
      assert :ok = ReplyWorker.perform(job)
      assert Repo.get!(Conversation, c.conversation.id).status == "failed"
    end

    assert Repo.aggregate(Message, :count) == 4
  end

  test "CLI timeout kills its process group, removes state, and never redelivers", c do
    blocked_cli(c.cli)
    job = enqueue(c)
    parent = self()

    expect(MuonTrap, :cmd, fn command, args, opts ->
      assert opts[:timeout] == 60_000
      send(parent, {:cwd, opts[:cd]})
      Mimic.call_original(MuonTrap, :cmd, [command, args, Keyword.put(opts, :timeout, 2_000)])
    end)

    assert ReplyWorker.timeout(job) == 90_000
    assert :ok = ReplyWorker.perform(job)
    assert_receive {:cwd, cwd}
    refute File.exists?(cwd)
    # The stub reports its own PID and its child outside the disposable cwd.
    assert_processes_stopped(c.cli)
    assert Repo.get!(Conversation, c.conversation.id).status == "failed"
    assert :ok = ReplyWorker.perform(job)
    assert Repo.aggregate(Message, :count) == 1
  end

  test "killing the worker kills blocked CLI children and cleans ephemeral state; recovery never restarts",
       c do
    blocked_cli(c.cli)
    job = enqueue(c)
    parent = self()

    expect(MuonTrap, :cmd, fn command, args, opts ->
      send(parent, {:cwd, opts[:cd]})
      Mimic.call_original(MuonTrap, :cmd, [command, args, opts])
    end)

    {worker, monitor} =
      spawn_monitor(fn ->
        receive do
          :run -> ReplyWorker.perform(job)
        end
      end)

    on_exit(fn -> Process.exit(worker, :kill) end)
    Mimic.allow(MuonTrap, self(), worker)
    send(worker, :run)
    assert_receive {:cwd, cwd}, 1_000
    wait_until(fn -> File.exists?(c.cli <> ".child") end)
    assert Repo.get!(Conversation, c.conversation.id).status == "running"
    Process.exit(worker, :kill)
    assert_receive {:DOWN, ^monitor, :process, ^worker, :killed}
    wait_until(fn -> not File.exists?(cwd) end)
    assert_processes_stopped(c.cli)

    from(m in Message, where: m.id == ^job.args["message_id"])
    |> Repo.update_all(set: [updated_at: DateTime.add(DateTime.utc_now(), -121)])

    assert :ok = RecoveryWorker.perform(%Oban.Job{})
    assert Repo.get!(Conversation, c.conversation.id).error == "inference_interrupted"
    assert :ok = ReplyWorker.perform(job)
    assert Repo.aggregate(Message, :count) == 1
  end

  defp enqueue(c) do
    id = Ecto.UUID.generate()

    Oban.Testing.with_testing_mode(:manual, fn ->
      {:ok, _} =
        Toki.send_message(c.user, c.project, c.conversation.id, %{
          "id" => id,
          "content" => "Hello",
          "harness" => "codex",
          "command" => "/bin/false",
          "model" => "untrusted"
        })
    end)

    Enum.find(all_enqueued(worker: ReplyWorker), &(&1.args["message_id"] == id))
  end

  defp option(args, key), do: args |> Enum.drop_while(&(&1 != key)) |> Enum.at(1)

  defp blocked_cli(cli) do
    File.write!(cli, """
    #!/bin/sh
    if [ "$1" = "--version" ]; then printf '2.1.285 (Claude Code)'; exit; fi
    trap '' TERM
    printf '%s' "$$" > '#{cli}.pid'
    sleep 60 &
    printf '%s' "$!" > '#{cli}.child'
    wait
    """)
  end

  defp assert_processes_stopped(cli) do
    for path <- [cli <> ".pid", cli <> ".child"] do
      pid = File.read!(path)

      wait_until(fn ->
        {_output, status} =
          MuonTrap.cmd("/bin/kill", ["-0", pid],
            into: "",
            stderr_to_stdout: true,
            timeout: 1_000
          )

        status != 0
      end)
    end
  end

  defp wait_until(predicate, remaining \\ 100) do
    if predicate.() do
      :ok
    else
      assert remaining > 0
      Process.sleep(20)
      wait_until(predicate, remaining - 1)
    end
  end
end
