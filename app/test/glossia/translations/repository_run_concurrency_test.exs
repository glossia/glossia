defmodule Glossia.Translations.RepositoryRunConcurrencyTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Glossia.Accounts.Account
  alias Glossia.Translations
  alias Glossia.Translations.Context
  alias Glossia.Translations.RepositoryRun
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.TranslationSession

  setup :set_mimic_global

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
    """)

    File.mkdir_p!(Path.join(root, "docs"))

    for name <- ["a-credit", "b-in-flight", "c-in-flight", "d-in-flight", "z-queued"] do
      File.write!(Path.join(root, "docs/#{name}.md"), "# #{name}\n")
    end

    git!(root, ["add", "."])
    git!(root, ["commit", "-q", "-m", "init"])
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
      source = payload["source_content"]
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
    assert_receive {:model_request, "# a-credit"}
    refute_receive {:model_request, "# z-queued"}, 100
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

    stub(Translations, :translate_stream, fn _account, payload, _on_event, _opts ->
      source = payload["source_content"]
      send(test_pid, {:model_request, source})

      if String.contains?(source, "a-credit") do
        {:error, %{reason: "Provider unavailable", status: 503, response_body: %{}}}
      else
        {:ok,
         %{
           text: source,
           model: "openai/gpt-5",
           provider: "openai",
           model_handle: "translator"
         }}
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
    assert failure.reason.kind == "provider-error"
    assert_receive {:model_request, "# z-queued"}
  end
end
