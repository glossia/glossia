defmodule Glossia.Translations.RepositoryRunIntegrationTest do
  @moduledoc """
  Exercises the native translation pipeline end to end against a real git working
  tree — plan → engine (read/translate/validate/write) → lockfile → `git status`
  collection — with only the Condukt LLM call stubbed. This is the closest check
  to a live run without a real model or a FLAME clone.
  """
  use ExUnit.Case, async: true
  use Mimic

  alias Glossia.Accounts.Account
  alias Glossia.Translations
  alias Glossia.Translations.RepositoryRun
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.TranslationSession

  defp git!(root, args) do
    {_out, 0} = MuonTrap.cmd("git", ["-C", root | args], stderr_to_stdout: true, into: "")
  end

  defp init_repo(root) do
    git!(root, ["init", "-q"])
    git!(root, ["config", "user.email", "t@example.com"])
    git!(root, ["config", "user.name", "Tester"])

    File.write!(Path.join(root, "GLOSSIA.md"), """
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

    Mimic.stub(Translations, :translate_stream, fn _account, payload, on_event ->
      assert payload["source_content"] == "# Guide\n\nHello, world."
      assert payload["locale"] == "es"
      on_event.(:turn_start)
      on_event.({:text, "# Guía"})
      on_event.(:done)

      {:ok,
       %{
         text: "# Guía\n\nHola, mundo.",
         model: "anthropic/x",
         provider: "anthropic",
         model_handle: "m"
       }}
    end)

    assert {:ok, changes} =
             RepositoryRun.translate_repository(session, %Account{id: 1}, root, ["es"],
               progress_node: Node.self()
             )

    # Output written to disk.
    output = Path.join([root, "docs", "i18n", "es", "guide.md"])
    assert File.read!(output) == "# Guía\n\nHola, mundo."

    # Lockfile written and valid.
    lock_path = Path.join([root, ".glossia", "docs/guide.md", "es.lock"])
    assert File.exists?(lock_path)
    assert {:ok, lock} = Jason.decode(File.read!(lock_path))
    assert lock["output_path"] == "docs/i18n/es/guide.md"

    assert %{"root" => %{"kind" => "translation_input", "children" => children}} =
             lock["hash_tree"]

    assert Enum.map(children, & &1["kind"]) == ["source", "translation_config", "context_bundle"]

    # Change list ready for the PR builder.
    paths = changes |> Enum.map(& &1.path) |> Enum.sort()
    assert "docs/i18n/es/guide.md" in paths
    assert ".glossia/docs/guide.md/es.lock" in paths
    assert Enum.all?(changes, &(&1.status == "added"))
    assert Enum.all?(changes, &is_binary(&1.content))

    # Live progress was broadcast.
    assert_receive {:translation_session_event, %{type: "plan", total: 1}}

    assert_receive {:translation_session_event,
                    %{type: "item_completed", output_path: "docs/i18n/es/guide.md"}}
  end

  @tag :tmp_dir
  test "skips a file whose lockfile is already current (no changes)", %{tmp_dir: root} do
    init_repo(root)
    session = %TranslationSession{id: Ecto.UUID.generate()}

    stub = fn ->
      Mimic.stub(Translations, :translate_stream, fn _account, _payload, _on_event ->
        {:ok,
         %{
           text: "# Guía\n\nHola.",
           model: "anthropic/x",
           provider: "anthropic",
           model_handle: "m"
         }}
      end)
    end

    stub.()

    assert {:ok, first} =
             RepositoryRun.translate_repository(session, %Account{id: 1}, root, ["es"])

    assert first != []

    # Commit the produced output + lockfile so the tree is clean, then re-run.
    git!(root, ["add", "."])
    git!(root, ["commit", "-q", "-m", "translations"])

    stub.()
    assert {:ok, []} = RepositoryRun.translate_repository(session, %Account{id: 1}, root, ["es"])
  end
end
