defmodule Glossia.Translations.RepositoryRunIntegrationTest do
  @moduledoc """
  Exercises the native translation pipeline end to end against a real git working
  tree — plan → engine (read/translate/validate/write) → lockfile → `git status`
  collection — with only the Condukt LLM call stubbed. This is the closest check
  to a live run without a real model or a FLAME clone.
  """
  use ExUnit.Case, async: true
  use Mimic

  import ExUnit.CaptureLog

  alias Glossia.Accounts.Account
  alias Glossia.Translations
  alias Glossia.Translations.Context
  alias Glossia.Translations.RepositoryRun
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.TranslationSession
  alias Glossia.TranslationStubs

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
    ---
    Project context
    """)

    File.mkdir_p!(Path.join(root, "docs"))
    File.write!(Path.join([root, "docs", "guide.md"]), "# Guide\n\nHello, world.")
    git!(root, ["add", "."])
    git!(root, ["commit", "-q", "-m", "init"])
  end

  @tag :tmp_dir
  test "translates a source file, writes output + lockfile, and collects the changes", %{
    tmp_dir: root
  } do
    init_repo(root)

    session = %TranslationSession{id: Ecto.UUID.generate()}
    :ok = TranslationSessions.subscribe_session_events(session)

    parent_node = :parent@translation

    Mimic.stub(Translations, :translate_stream, fn _account, payload, on_event, opts ->
      assert TranslationStubs.unit_texts(payload) == ["Guide", "Hello, world."]
      assert payload["locale"] == "es"
      assert opts[:credential_node] == parent_node
      on_event.(:turn_start)
      on_event.({:text, "# Guía"})
      on_event.(:done)

      {:ok,
       %{
         text: spanish(payload),
         model: "anthropic/x",
         provider: "anthropic",
         model_handle: "m"
       }}
    end)

    assert {:ok, changes} =
             RepositoryRun.translate_repository(session, %Account{id: 1}, root, ["es"],
               progress_node: Node.self(),
               credential_node: parent_node,
               context_snapshot: Context.empty_snapshot()
             )

    # Output written to disk.
    output = Path.join([root, "docs", "i18n", "es", "guide.md"])
    assert File.read!(output) == "# Guía\n\nHola, mundo."

    # Lockfile written and valid.
    lock_path = Path.join([root, ".glossia", "docs/guide.md", "es.lock"])
    assert File.exists?(lock_path)
    assert {:ok, lock} = JSON.decode(File.read!(lock_path))
    assert lock["output_path"] == "docs/i18n/es/guide.md"

    assert %{"root" => %{"kind" => "translation_input", "children" => children}} =
             lock["hash_tree"]

    assert Enum.map(children, & &1["kind"]) == ["source", "translation_config", "context_bundle"]
    refute Map.has_key?(lock["server_context"]["glossary"], "term_keys")

    # Change list ready for the PR builder.
    paths = changes |> Enum.map(& &1.path) |> Enum.sort()
    assert "docs/i18n/es/guide.md" in paths
    assert ".glossia/docs/guide.md/es.lock" in paths
    assert Enum.all?(changes, &(&1.status == "added"))
    assert Enum.all?(changes, &is_binary(&1.content))

    # Live progress was broadcast.
    assert_receive {:translation_session_event, %{type: "plan", total: 1}}

    assert_receive {:translation_session_event,
                    %{
                      type: "plan_assessed",
                      total: 1,
                      needs_translation: 1,
                      up_to_date: 0,
                      queued: [
                        %{
                          source_path: "docs/guide.md",
                          translation_reasons: ["lockfile_missing", "output_missing"],
                          translation_diff: %{
                            "baseline" => "missing_lockfile",
                            "tree" => %{"kind" => "translation_input"}
                          }
                        }
                      ]
                    }}

    assert_receive {:translation_session_event,
                    %{
                      type: "item_completed",
                      output_path: "docs/i18n/es/guide.md",
                      output_preview: "# Guía\n\nHola, mundo.",
                      model_calls: 1
                    }}
  end

  @tag :tmp_dir
  test "publishes a completed file before another file fails", %{tmp_dir: root} do
    init_repo(root)
    File.write!(Path.join(root, "docs/broken.md"), "# Broken\n\nThis one fails.")
    git!(root, ["add", "."])
    git!(root, ["commit", "-q", "-m", "add broken source"])

    session = %TranslationSession{id: Ecto.UUID.generate()}
    test_pid = self()

    Mimic.stub(Translations, :translate_stream, fn _account, payload, _on_event, _opts ->
      case TranslationStubs.unit_texts(payload) do
        ["Broken", "This one fails."] ->
          {:error, %{reason: "provider unavailable", status: 503, response_body: %{}}}

        _ ->
          {:ok,
           %{
             text: spanish(payload),
             model: "openai/gpt-5",
             provider: "openai",
             model_handle: "translator"
           }}
      end
    end)

    publish = fn changes ->
      send(test_pid, {:published_item, changes})
      :ok
    end

    assert {:error, {:translation_items_failed, failures}} =
             RepositoryRun.translate_repository(session, %Account{id: 1}, root, ["es"],
               context_snapshot: Context.empty_snapshot(),
               credential_node: Node.self(),
               after_item_completed: publish
             )

    assert Enum.any?(failures, &(&1.output_path == "docs/i18n/es/broken.md"))

    assert_receive {:published_item, changes}

    assert changes
           |> Enum.map(& &1.path)
           |> Enum.sort() == [
             ".glossia/docs/guide.md/es.lock",
             "docs/i18n/es/guide.md"
           ]
  end

  @tag :tmp_dir
  test "publishes only owned artifacts even while unrelated files are unreadable", %{
    tmp_dir: root
  } do
    init_repo(root)
    File.ln_s!("missing-target", Path.join(root, "unrelated.md"))
    File.write!(Path.join(root, "validator-output.txt"), "private validator log")
    test_pid = self()

    Mimic.stub(Translations, :translate_stream, fn _account, payload, _on_event ->
      {:ok, %{text: spanish(payload), model: "openai/gpt-5", provider: "openai"}}
    end)

    publish = fn changes ->
      send(test_pid, {:published, changes})
      :ok
    end

    assert {:ok, changes} =
             RepositoryRun.translate_repository(
               %TranslationSession{id: Ecto.UUID.generate()},
               %Account{id: 1},
               root,
               ["es"],
               context_snapshot: Context.empty_snapshot(),
               after_item_completed: publish
             )

    assert_receive {:published, ^changes}
    assert length(changes) == 2
    refute Enum.any?(changes, &(&1.path == "unrelated.md"))
    assert {:ok, %{type: :symlink}} = File.lstat(Path.join(root, "unrelated.md"))
  end

  @tag :tmp_dir
  test "a plan with no selected items never publishes unrelated checkout changes", %{
    tmp_dir: root
  } do
    init_repo(root)
    File.write!(Path.join(root, "unrelated.md"), "private validator log")

    assert {:ok, []} =
             RepositoryRun.translate_repository(
               %TranslationSession{id: Ecto.UUID.generate()},
               %Account{id: 1},
               root,
               ["ja"],
               context_snapshot: Context.empty_snapshot()
             )
  end

  @tag :tmp_dir
  test "an empty owned manifest is a successful no-op without calling the publisher", %{
    tmp_dir: root
  } do
    init_repo(root)
    Mimic.stub(MuonTrap, :cmd, fn "git", _args, _opts -> {"", 0} end)

    Mimic.stub(Translations, :translate_stream, fn _account, payload, _on_event ->
      {:ok, %{text: spanish(payload), model: "openai/gpt-5", provider: "openai"}}
    end)

    assert {:ok, []} =
             RepositoryRun.translate_repository(
               %TranslationSession{id: Ecto.UUID.generate()},
               %Account{id: 1},
               root,
               ["es"],
               context_snapshot: Context.empty_snapshot(),
               after_item_completed: fn _ ->
                 flunk("unchanged artifacts must not be published")
               end
             )
  end

  @tag :tmp_dir
  test "classifies publication callback exceptions without exposing their contents", %{
    tmp_dir: root
  } do
    init_repo(root)

    Mimic.stub(Translations, :translate_stream, fn _account, payload, _on_event ->
      {:ok, %{text: spanish(payload), model: "openai/gpt-5", provider: "openai"}}
    end)

    log =
      capture_log(fn ->
        assert {:error, {:translation_items_failed, [failure]}} =
                 RepositoryRun.translate_repository(
                   %TranslationSession{id: Ecto.UUID.generate()},
                   %Account{id: 1},
                   root,
                   ["es"],
                   context_snapshot: Context.empty_snapshot(),
                   after_item_completed: fn _changes -> raise "TOKEN=private-output" end
                 )

        assert failure.reason.kind == "publication-failed"
        assert failure.reason.publication_code == "callback-failed"
        assert failure.reason.scope == "session"
      end)

    assert log =~ ~s("publication_code":"callback-failed")
    refute log =~ "TOKEN=private-output"
  end

  @tag :tmp_dir
  test "keeps model thinking out of structured progress events", %{tmp_dir: root} do
    init_repo(root)

    session = %TranslationSession{id: Ecto.UUID.generate()}
    :ok = TranslationSessions.subscribe_session_events(session)

    Mimic.stub(Translations, :translate_stream, fn _account, payload, on_event, _opts ->
      on_event.(:turn_start)
      Enum.each(1..500, fn n -> on_event.({:thinking, "chunk #{n} "}) end)
      on_event.({:text, "# Guía"})
      on_event.(:done)

      {:ok,
       %{
         text: spanish(payload),
         model: "anthropic/x",
         provider: "anthropic",
         model_handle: "m"
       }}
    end)

    assert {:ok, _changes} =
             RepositoryRun.translate_repository(session, %Account{id: 1}, root, ["es"],
               progress_node: Node.self(),
               credential_node: Node.self(),
               context_snapshot: Context.empty_snapshot()
             )

    events =
      collect_session_events([])
      |> Enum.filter(&match?(%{type: "item_event"}, &1))
      |> Enum.map(& &1.event)

    refute Enum.any?(events, &(&1.type == "thinking"))
    assert Enum.any?(events, &(&1.type == "segment_start"))
    assert Enum.any?(events, &(&1.type == "segment_output"))
  end

  defp spanish(payload) do
    TranslationStubs.respond(payload, fn
      "Guide" -> "Guía"
      "Hello, world." -> "Hola, mundo."
      "Reference" -> "Referencia"
      "Use the guide." -> "Usa la guía."
      text -> "ES " <> text
    end)
  end

  defp collect_session_events(acc) do
    receive do
      {:translation_session_event, event} -> collect_session_events([event | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  @tag :tmp_dir
  test "returns all staged translations in one changeset after every item succeeds", %{
    tmp_dir: root
  } do
    init_repo(root)
    File.write!(Path.join([root, "docs", "reference.md"]), "# Reference\n\nUse the guide.")
    git!(root, ["add", "."])
    git!(root, ["commit", "-q", "-m", "add reference"])

    session = %TranslationSession{id: Ecto.UUID.generate()}

    Mimic.stub(Translations, :translate_stream, fn _account, payload, _on_event ->
      {:ok,
       %{
         text: spanish(payload),
         model: "openai/gpt-5",
         provider: "openai",
         model_handle: "translator"
       }}
    end)

    assert {:ok, changes} =
             RepositoryRun.translate_repository(session, %Account{id: 1}, root, ["es"],
               context_snapshot: Context.empty_snapshot()
             )

    assert length(changes) == 4
  end

  @tag :tmp_dir
  test "rejects empty translated documents without writing or publishing them", %{tmp_dir: root} do
    init_repo(root)
    session = %TranslationSession{id: Ecto.UUID.generate()}

    Mimic.stub(Translations, :translate_stream, fn _account, _payload, _on_event ->
      {:ok,
       %{
         text: "",
         model: "openai/gpt-5",
         provider: "openai",
         model_handle: "translator"
       }}
    end)

    log =
      capture_log(fn ->
        assert {:error, {:translation_items_failed, [failure]}} =
                 RepositoryRun.translate_repository(session, %Account{id: 1}, root, ["es"],
                   context_snapshot: Context.empty_snapshot()
                 )

        assert failure.reason.kind == "validation-empty-output"
        assert failure.reason.validation_code == "empty-output"
      end)

    item_log =
      log |> String.split("\n") |> Enum.find(&String.contains?(&1, "Translation item failed:"))

    assert item_log =~ ~s("validation_code":"empty-output")
    assert item_log =~ ~s("translation_session_id":"#{session.id}")
    refute File.exists?(Path.join([root, "docs", "i18n", "es", "guide.md"]))
  end

  @tag :tmp_dir
  test "skips a file whose lockfile is already current (no changes)", %{tmp_dir: root} do
    init_repo(root)
    session = %TranslationSession{id: Ecto.UUID.generate()}

    stub = fn ->
      Mimic.stub(Translations, :translate_stream, fn _account, payload, _on_event ->
        {:ok,
         %{
           text: spanish(payload),
           model: "anthropic/x",
           provider: "anthropic",
           model_handle: "m"
         }}
      end)
    end

    stub.()

    assert {:ok, first} =
             RepositoryRun.translate_repository(session, %Account{id: 1}, root, ["es"],
               context_snapshot: Context.empty_snapshot()
             )

    assert first != []

    # Commit the produced output + lockfile so the tree is clean, then re-run.
    git!(root, ["add", "."])
    git!(root, ["commit", "-q", "-m", "translations"])

    stub.()
    TranslationSessions.subscribe_session_events(session)

    assert {:ok, []} =
             RepositoryRun.translate_repository(session, %Account{id: 1}, root, ["es"],
               context_snapshot: Context.empty_snapshot()
             )

    # The whole point of the assessment: the session reports that there is
    # nothing to do rather than going silent with no items.
    assert_receive {:translation_session_event,
                    %{type: "plan_assessed", total: 1, needs_translation: 0, up_to_date: 1}}

    refute_receive {:translation_session_event, %{type: "item_started"}}
  end

  @tag :tmp_dir
  test "reports an unreadable source instead of aborting the whole run", %{tmp_dir: root} do
    init_repo(root)

    # A second source that the assessment cannot read. It must not take the
    # readable file down with it.
    File.write!(Path.join([root, "docs", "broken.md"]), "# Broken\n\nHello.")
    File.chmod!(Path.join([root, "docs", "broken.md"]), 0o000)
    on_exit(fn -> File.chmod(Path.join([root, "docs", "broken.md"]), 0o644) end)

    session = %TranslationSession{id: Ecto.UUID.generate()}
    TranslationSessions.subscribe_session_events(session)

    Mimic.stub(Translations, :translate_stream, fn _account, payload, _on_event ->
      {:ok,
       %{text: spanish(payload), model: "openai/gpt-5", provider: "openai", model_handle: "m"}}
    end)

    assert {:error, {:translation_items_failed, failures}} =
             RepositoryRun.translate_repository(session, %Account{id: 1}, root, ["es"],
               context_snapshot: Context.empty_snapshot()
             )

    assert [%{output_path: "docs/i18n/es/broken.md", reason: reason}] = failures
    assert reason.kind == "source-unreadable"

    assert_receive {:translation_session_event,
                    %{type: "item_failed", output_path: "docs/i18n/es/broken.md"}}

    # The readable file was still translated in the isolated checkout.
    assert_receive {:translation_session_event,
                    %{type: "item_completed", output_path: "docs/i18n/es/guide.md"}}
  end

  @tag :tmp_dir
  test "does not publish staged files when another file fails", %{
    tmp_dir: root
  } do
    init_repo(root)
    File.write!(Path.join([root, "docs", "broken.md"]), <<"Invalid ", 0xFF, " text">>)
    git!(root, ["add", "."])
    git!(root, ["commit", "-q", "-m", "add invalid source"])

    session = %TranslationSession{id: Ecto.UUID.generate()}
    :ok = TranslationSessions.subscribe_session_events(session)

    Mimic.stub(Translations, :translate_stream, fn _account, payload, _on_event ->
      {:ok,
       %{
         text: spanish(payload),
         model: "openai/gpt-5",
         provider: "openai",
         model_handle: "translator"
       }}
    end)

    assert {:error, {:translation_items_failed, [failure]}} =
             RepositoryRun.translate_repository(session, %Account{id: 1}, root, ["es"],
               context_snapshot: Context.empty_snapshot()
             )

    assert failure.output_path == "docs/i18n/es/broken.md"
    assert failure.locale == "es"
    assert failure.reason.kind == "source-invalid-encoding"
    assert failure.reason.scope == "item"
    assert File.exists?(Path.join([root, "docs", "i18n", "es", "guide.md"]))
    refute File.exists?(Path.join([root, "docs", "i18n", "es", "broken.md"]))

    assert_receive {:translation_session_event,
                    %{
                      type: "item_failed",
                      output_path: "docs/i18n/es/broken.md",
                      reason: %{kind: "source-invalid-encoding", scope: "item"}
                    }}

    assert_receive {:translation_session_event,
                    %{
                      type: "item_completed",
                      output_path: "docs/i18n/es/guide.md"
                    }}
  end

  @tag :tmp_dir
  test "broadcasts a safe provider failure without request contents or credentials", %{
    tmp_dir: root
  } do
    init_repo(root)
    session = %TranslationSession{id: Ecto.UUID.generate()}
    :ok = TranslationSessions.subscribe_session_events(session)

    Mimic.stub(Translations, :translate_stream, fn _account, _payload, on_event ->
      reason = %{
        reason: "Credit limit exceeded",
        status: 402,
        response_body: %{"type" => "credit_limit"},
        request_body: %{"prompt" => "private source document"},
        headers: [
          {"authorization", "Bearer provider-secret"},
          {"x-request-id", "request_123"}
        ]
      }

      on_event.({:error, reason})
      {:error, reason}
    end)

    assert {:error, {:translation_items_failed, [failure]}} =
             RepositoryRun.translate_repository(session, %Account{id: 1}, root, ["es"],
               context_snapshot: Context.empty_snapshot()
             )

    assert failure.reason == %{
             kind: "provider-credit",
             scope: "session",
             provider: "openai",
             status: 402,
             code: "credit_limit",
             request_id: "request_123",
             retry_after_ms: nil
           }

    refute inspect(failure) =~ "private source document"
    refute inspect(failure) =~ "provider-secret"

    assert_receive {:translation_session_event,
                    %{type: "item_failed", reason: %{kind: "provider-credit"} = reason}}

    refute inspect(reason) =~ "private source document"
    refute inspect(reason) =~ "provider-secret"
  end

  @tag :tmp_dir
  test "fails the repository run when a custom format has no validation command", %{
    tmp_dir: root
  } do
    File.write!(Path.join(root, "L10N.md"), """
    ---
    source_language: en
    model: openai/gpt-5
    sources:
      "docs/*.custom": "docs/i18n/{locale}/{relpath}"
    targets:
      es: Spanish
    ---
    """)

    File.mkdir_p!(Path.join(root, "docs"))
    File.write!(Path.join([root, "docs", "guide.custom"]), "title(value)")
    session = %TranslationSession{id: Ecto.UUID.generate()}

    assert {:error, {:planning_failed, message}} =
             RepositoryRun.translate_repository(session, %Account{id: 1}, root, ["es"],
               context_snapshot: Context.empty_snapshot()
             )

    assert message =~ "no built-in format adapter for .custom files"
  end
end
