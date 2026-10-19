defmodule Glossia.Translations.RepositoryRunConcurrencyTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Glossia.Accounts.Account
  alias Glossia.Translations
  alias Glossia.Translations.Context
  alias Glossia.Translations.RepositoryRun
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.PublicationBatch
  alias Glossia.TranslationSessions.TranslationSession
  alias Glossia.TranslationStubs

  setup :set_mimic_global

  defp git!(root, args) do
    {_out, 0} =
      MuonTrap.cmd(
        "git",
        ["-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "-C", root | args],
        stderr_to_stdout: true,
        into: "",
        timeout: 10_000
      )
  end

  defp init_repo(root) do
    git!(root, ["init", "-q"])
    git!(root, ["config", "user.email", "t@example.com"])
    git!(root, ["config", "user.name", "Tester"])

    File.write!(Path.join(root, "L10N.md"), """
    ---
    source_language: en
    model: openai/gpt-5
    sources:
      "docs/*.md": "docs/i18n/{locale}/*.md"
    targets:
      es: Spanish
      de: German
      ja: Japanese
      pt-BR: Brazilian Portuguese
      zh-Hans: Simplified Chinese
      fr: French
      ko: Korean
    ---
    """)

    File.mkdir_p!(Path.join(root, "docs"))

    for name <- ["a-credit", "b-in-flight", "c-in-flight", "d-in-flight", "z-queued"] do
      File.write!(Path.join(root, "docs/#{name}.md"), "# #{name}\n")
    end

    git!(root, ["add", "."])
    git!(root, ["commit", "-q", "-m", "init"])
  end

  @tag :tmp_dir
  @tag timeout: 120_000
  test "repeated concurrent runs publish every output and lockfile with exact contents", %{
    tmp_dir: root
  } do
    stub(TranslationSessions, :broadcast_session_event, fn _session, _event -> :ok end)
    stub(TranslationSessions, :heartbeat_session, fn _session_id -> :ok end)

    stub(Translations, :translate_stream, fn _account, payload, _on_event, _opts ->
      {:ok,
       %{
         text: TranslationStubs.respond(payload, &("ES " <> &1)),
         model: "openai/gpt-5",
         provider: "openai"
       }}
    end)

    published = start_supervised!({Agent, fn -> %{} end})

    for pass <- 1..3 do
      repo = Path.join(root, "run-#{pass}")
      File.mkdir_p!(repo)
      init_repo(repo)

      for n <- 1..44 do
        File.write!(
          Path.join(repo, "docs/#{n}-#{String.duplicate("x", 80)}.md"),
          "# Document #{n}\n"
        )
      end

      git!(repo, ["add", "."])
      git!(repo, ["commit", "-q", "-m", "add corpus"])
      Agent.update(published, fn _ -> %{} end)

      {:ok, batch} =
        PublicationBatch.start_link(
          fn changes ->
            Agent.update(published, fn acc ->
              Enum.reduce(changes, acc, &Map.put(&2, &1.path, &1.content))
            end)

            :ok
          end,
          max_files: 25
        )

      try do
        assert {:ok, changes} =
                 RepositoryRun.translate_repository(
                   %TranslationSession{id: Ecto.UUID.generate()},
                   %Account{id: Ecto.UUID.generate()},
                   repo,
                   ["es", "de", "ja", "pt-BR", "zh-Hans", "fr", "ko"],
                   context_snapshot: Context.empty_snapshot(),
                   credential_node: Node.self(),
                   translation_concurrency: 16,
                   after_item_completed: &PublicationBatch.add(batch, &1)
                 )

        assert :ok = PublicationBatch.flush(batch)
        assert length(changes) == 686
        assert Enum.sum(Enum.map(changes, &(byte_size(&1.path) + 4))) > 65_536
        assert Enum.all?(changes, &(&1.status == "added"))
        assert Map.new(changes, &{&1.path, &1.content}) == Agent.get(published, & &1)

        for change <- changes do
          assert change.content == File.read!(Path.join(repo, change.path))

          if String.ends_with?(change.path, ".lock") do
            lock = JSON.decode!(change.content)
            assert File.read!(Path.join(repo, lock["output_path"])) =~ "# ES "
          else
            assert change.content =~ "# ES "
          end
        end
      after
        PublicationBatch.stop(batch)
      end
    end
  end

  @tag :tmp_dir
  @tag timeout: 2_000
  test "does not schedule queued files after a permanent provider failure", %{tmp_dir: root} do
    assert Mimic.mode() == :global
    init_repo(root)
    test_pid = self()

    stub(TranslationSessions, :broadcast_session_event, fn _session, _event ->
      :ok
    end)

    stub(TranslationSessions, :heartbeat_session, fn _session_id ->
      :ok
    end)

    stub(Translations, :translate_stream, fn _account, payload, _on_event, _opts ->
      source = payload |> TranslationStubs.unit_texts() |> hd()
      send(test_pid, {:model_request, source})

      if String.contains?(source, "a-credit") do
        {:error,
         %{
           reason: "Credit limit exceeded",
           status: 402,
           response_body: %{"type" => "credit_limit"}
         }}
      else
        Process.sleep(:infinity)
      end
    end)

    assert {:error, {:translation_items_failed, [failure]}} =
             RepositoryRun.translate_repository(
               %TranslationSession{id: Ecto.UUID.generate()},
               %Account{id: Ecto.UUID.generate()},
               root,
               ["es"],
               context_snapshot: Context.empty_snapshot(),
               credential_node: Node.self(),
               translation_concurrency: 4
             )

    assert failure.output_path == "docs/i18n/es/a-credit.md"
    assert failure.reason.kind == "provider-credit"
    assert_receive {:model_request, "a-credit"}
    refute_receive {:model_request, "z-queued"}, 100
  end

  @tag :tmp_dir
  @tag timeout: 2_000
  test "does not schedule queued files after exhausted rate limits", %{tmp_dir: root} do
    assert Mimic.mode() == :global
    init_repo(root)
    test_pid = self()

    stub(TranslationSessions, :broadcast_session_event, fn _session, _event ->
      :ok
    end)

    stub(TranslationSessions, :heartbeat_session, fn _session_id ->
      :ok
    end)

    stub(Translations, :translate_stream, fn _account, payload, _on_event, _opts ->
      source = payload |> TranslationStubs.unit_texts() |> hd()
      send(test_pid, {:model_request, source})

      if String.contains?(source, "a-credit") do
        {:error,
         %{
           reason: "Provider rate limit reached",
           status: 429,
           response_body: %{"type" => "dynamic_rate_limit"}
         }}
      else
        Process.sleep(:infinity)
      end
    end)

    assert {:error, {:translation_items_failed, [failure]}} =
             RepositoryRun.translate_repository(
               %TranslationSession{id: Ecto.UUID.generate()},
               %Account{id: Ecto.UUID.generate()},
               root,
               ["es"],
               context_snapshot: Context.empty_snapshot(),
               credential_node: Node.self(),
               translation_concurrency: 4
             )

    assert failure.output_path == "docs/i18n/es/a-credit.md"
    assert failure.reason.kind == "provider-rate-limit"
    assert_receive {:model_request, "a-credit"}
    refute_receive {:model_request, "z-queued"}, 100
  end

  @tag :tmp_dir
  @tag timeout: 2_000
  test "continues scheduling queued files after a transient provider failure", %{tmp_dir: root} do
    assert Mimic.mode() == :global
    init_repo(root)
    test_pid = self()

    stub(TranslationSessions, :broadcast_session_event, fn _session, _event ->
      :ok
    end)

    stub(TranslationSessions, :heartbeat_session, fn _session_id ->
      :ok
    end)

    {:ok, attempts} = Elixir.Agent.start_link(fn -> 0 end)

    stub(Translations, :translate_stream, fn _account, payload, _on_event, _opts ->
      source = payload |> TranslationStubs.unit_texts() |> hd()
      send(test_pid, {:model_request, source})

      first_transient_attempt =
        String.contains?(source, "a-credit") and
          Elixir.Agent.get_and_update(attempts, fn attempt -> {attempt == 0, attempt + 1} end)

      if first_transient_attempt do
        {:error, %{reason: "Provider unavailable", status: 503, response_body: %{}}}
      else
        {:ok,
         %{
           text: TranslationStubs.respond(payload, & &1),
           model: "openai/gpt-5",
           provider: "openai",
           model_handle: "translator"
         }}
      end
    end)

    assert {:ok, changes} =
             RepositoryRun.translate_repository(
               %TranslationSession{id: Ecto.UUID.generate()},
               %Account{id: Ecto.UUID.generate()},
               root,
               ["es"],
               context_snapshot: Context.empty_snapshot(),
               credential_node: Node.self(),
               translation_concurrency: 4
             )

    assert Enum.any?(changes, &(&1.path == "docs/i18n/es/a-credit.md"))
    assert_receive {:model_request, "z-queued"}
    assert_receive {:model_request, "a-credit"}
    assert_receive {:model_request, "a-credit"}
  end

  # A barrier is the only honest way to assert fan-out: every file blocks until
  # all of them have arrived, so the run can only finish if they were genuinely
  # in flight together. A capped run deadlocks here instead of passing slowly.
  defp barrier_stub(test_pid) do
    stub(Translations, :translate_stream, fn _account, payload, _on_event, _opts ->
      source = payload |> TranslationStubs.unit_texts() |> hd()
      send(test_pid, {:started, source, self()})

      receive do
        :proceed -> :ok
      after
        1_000 -> :ok
      end

      {:ok,
       %{
         text: TranslationStubs.respond(payload, & &1),
         model: "openai/gpt-5",
         provider: "openai",
         model_handle: "translator"
       }}
    end)
  end

  defp collect_started(count) do
    for _ <- 1..count do
      assert_receive {:started, source, pid}, 1_000
      {source, pid}
    end
  end

  @tag :tmp_dir
  @tag timeout: 10_000
  test "translates every planned file at once when no cap is configured", %{tmp_dir: root} do
    assert Mimic.mode() == :global
    init_repo(root)
    test_pid = self()

    stub(TranslationSessions, :broadcast_session_event, fn _session, _event -> :ok end)
    stub(TranslationSessions, :heartbeat_session, fn _session_id -> :ok end)
    barrier_stub(test_pid)

    task =
      Task.async(fn ->
        RepositoryRun.translate_repository(
          %TranslationSession{id: Ecto.UUID.generate()},
          %Account{id: Ecto.UUID.generate()},
          root,
          ["es"],
          context_snapshot: Context.empty_snapshot(),
          credential_node: Node.self()
        )
      end)

    # All five files are in flight simultaneously; with the old fixed cap of
    # four the fifth could not have started until one of the others returned.
    started = collect_started(5)
    assert length(started) == 5
    Enum.each(started, fn {_source, pid} -> send(pid, :proceed) end)

    assert {:ok, _changes} = Task.await(task, 8_000)
  end

  @tag :tmp_dir
  @tag timeout: 10_000
  test "still honours an explicitly configured cap", %{tmp_dir: root} do
    assert Mimic.mode() == :global
    init_repo(root)
    test_pid = self()

    stub(TranslationSessions, :broadcast_session_event, fn _session, _event -> :ok end)
    stub(TranslationSessions, :heartbeat_session, fn _session_id -> :ok end)
    barrier_stub(test_pid)

    task =
      Task.async(fn ->
        RepositoryRun.translate_repository(
          %TranslationSession{id: Ecto.UUID.generate()},
          %Account{id: Ecto.UUID.generate()},
          root,
          ["es"],
          context_snapshot: Context.empty_snapshot(),
          credential_node: Node.self(),
          translation_concurrency: 2
        )
      end)

    started = collect_started(2)
    refute_receive {:started, _source, _pid}, 200
    Enum.each(started, fn {_source, pid} -> send(pid, :proceed) end)

    # Release each remaining file as it is scheduled rather than letting it sit
    # on the barrier's fallback, so the test leaves nothing running behind it.
    for _ <- 1..3 do
      assert_receive {:started, _source, pid}, 2_000
      send(pid, :proceed)
    end

    assert {:ok, _changes} = Task.await(task, 8_000)
  end
end
