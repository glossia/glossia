defmodule Glossia.Translations.ContextResolutionTest do
  use Glossia.DataCase, async: false
  use Mimic

  alias Glossia.Glossaries
  alias Glossia.TestHelpers
  alias Glossia.Translations
  alias Glossia.Translations.Context
  alias Glossia.Translations.RepositoryRun
  alias Glossia.TranslationSessions.TranslationSession
  alias Glossia.Voices

  test "captures immutable versions and resolves locale-specific source context" do
    user = TestHelpers.create_user("context-resolution@example.com", "context-resolution")

    assert {:ok, %{voice: voice}} =
             Voices.create_voice(
               user.account,
               %{
                 tone: "authoritative",
                 formality: "formal",
                 target_audience: "Enterprise customers",
                 guidelines: "Use concise sentences.",
                 target_countries: ["MX", "US"],
                 cultural_notes: %{
                   "MX" => "Use respectful and direct language.",
                   "US" => "Use American English."
                 },
                 overrides: [
                   %{
                     locale: "es",
                     guidelines: "Usa un español claro."
                   },
                   %{
                     locale: "es-MX",
                     guidelines: "Evita anglicismos innecesarios."
                   }
                 ]
               },
               nil
             )

    assert {:ok, %{glossary: glossary}} =
             Glossaries.create_glossary(
               user.account,
               %{
                 entries: [
                   %{
                     term: "Account",
                     definition: "A customer organization.",
                     translations: [%{locale: "es-MX", translation: "Cuenta"}]
                   },
                   %{
                     term: "Workspace",
                     translations: [%{locale: "es", translation: "Espacio de trabajo"}]
                   }
                 ]
               },
               nil
             )

    assert {:ok, snapshot} = Context.snapshot(user.account)
    assert snapshot.voice_version == voice.version
    assert snapshot.glossary_version == glossary.version

    assert {:ok, _newer_voice} =
             Voices.create_voice(
               user.account,
               %{guidelines: "This must not affect the captured run."},
               nil
             )

    assert {:ok, _newer_glossary} =
             Glossaries.create_glossary(
               user.account,
               %{
                 entries: [
                   %{
                     term: "Account",
                     translations: [%{locale: "es-MX", translation: "Cliente"}]
                   }
                 ]
               },
               nil
             )

    query_counts = :counters.new(2, [])
    handler_id = {__MODULE__, self()}

    :ok =
      :telemetry.attach(
        handler_id,
        [:glossia, :repo, :query],
        fn _event, _measurements, metadata, counts ->
          cond do
            String.contains?(metadata.query, ~s(FROM "voices")) ->
              :counters.add(counts, 1, 1)

            String.contains?(metadata.query, ~s(FROM "glossaries")) ->
              :counters.add(counts, 2, 1)

            true ->
              :ok
          end
        end,
        query_counts
      )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    assert {:ok, [bundle, workspace_bundle, fallback_bundle]} =
             Context.resolve_many(
               user.account,
               snapshot,
               [
                 %{locale: "es-MX", source: "Create an Account.", preserve: []},
                 %{locale: "es-MX", source: "Open the Workspace.", preserve: []},
                 %{locale: "es-AR", source: "Open the Workspace.", preserve: []}
               ]
             )

    assert :counters.get(query_counts, 1) == 2
    assert :counters.get(query_counts, 2) == 2

    assert bundle.voice.guidelines == "Evita anglicismos innecesarios."
    assert bundle.voice.cultural_notes["MX"] == "Use respectful and direct language."
    assert [%{term: "Account", translation: "Cuenta"}] = bundle.terminology

    assert [%{term: "Workspace", translation: "Espacio de trabajo"}] =
             workspace_bundle.terminology

    assert fallback_bundle.voice.guidelines == "Usa un español claro."

    assert [%{term: "Workspace", translation: "Espacio de trabajo"}] =
             fallback_bundle.terminology

    prompt = Context.prompt_body(bundle, "Create an Account.", [])
    assert prompt =~ "Evita anglicismos innecesarios."
    assert prompt =~ "Cultural guidance for MX"
    assert prompt =~ ~s("Account" → "Cuenta")
    refute prompt =~ "Workspace"
    refute prompt =~ "American English"
  end

  test "uses the closest locale fallback before the base language" do
    user = TestHelpers.create_user("context-script-fallback@example.com", "script-fallback")

    assert {:ok, _voice} =
             Voices.create_voice(
               user.account,
               %{
                 guidelines: "Base voice",
                 cultural_notes: %{"CN" => "Use terminology familiar in mainland China."},
                 overrides: [
                   %{locale: "zh", guidelines: "Chinese voice"},
                   %{locale: "zh-Hans", guidelines: "Simplified Chinese voice"}
                 ]
               },
               nil
             )

    assert {:ok, _glossary} =
             Glossaries.create_glossary(
               user.account,
               %{
                 entries: [
                   %{
                     term: "Account",
                     translations: [
                       %{locale: "zh", translation: "帳戶"},
                       %{locale: "zh-Hans", translation: "账户"}
                     ]
                   }
                 ]
               },
               nil
             )

    assert {:ok, snapshot} = Context.snapshot(user.account)

    assert {:ok, [bundle]} =
             Context.resolve_many(
               user.account,
               snapshot,
               [%{locale: "zh-Hans-CN", source: "Open the Account.", preserve: []}]
             )

    assert bundle.voice.guidelines == "Simplified Chinese voice"
    assert [%{term: "Account", translation: "账户"}] = bundle.terminology

    prompt = Context.prompt_body(bundle, "Open the Account.", [])
    assert prompt =~ "Cultural guidance for CN"
    assert prompt =~ "Use terminology familiar in mainland China."
  end

  @tag :tmp_dir
  test "repository translation uses resolved context and records raw-free provenance", %{
    tmp_dir: root
  } do
    user = TestHelpers.create_user("context-repository@example.com", "context-repository")

    assert {:ok, %{voice: voice}} =
             Voices.create_voice(
               user.account,
               %{tone: "formal", guidelines: "Use concise sentences."},
               nil
             )

    assert {:ok, %{glossary: glossary}} =
             Glossaries.create_glossary(
               user.account,
               %{
                 entries: [
                   %{
                     term: "Account",
                     translations: [%{locale: "es", translation: "Cuenta"}]
                   }
                 ]
               },
               nil
             )

    initialize_repository(root)

    Mimic.stub(Translations, :translate_stream, fn _account, payload, _on_event ->
      assert payload["server_context_body"] =~ "Use concise sentences."
      assert payload["server_context_body"] =~ ~s("Account" → "Cuenta")

      {:ok,
       %{
         text: "Crea una Cuenta.",
         model: "openai/gpt-5",
         provider: "openai",
         model_handle: "translator"
       }}
    end)

    session = %TranslationSession{id: Ecto.UUID.generate()}

    assert {:ok, changes} =
             RepositoryRun.translate_repository(session, user.account, root, ["es"])

    assert Enum.any?(changes, &(&1.path == "docs/i18n/es/guide.md"))

    lock_path = Path.join([root, ".glossia", "docs/guide.md", "es.lock"])
    lock = lock_path |> File.read!() |> Jason.decode!()

    assert get_in(lock, ["server_context", "voice", "version"]) == voice.version

    assert get_in(lock, ["server_context", "terminology", "glossary_version"]) ==
             glossary.version

    refute Map.has_key?(lock["server_context"]["terminology"], "term_keys")
    refute File.read!(lock_path) =~ "Cuenta"
    refute File.read!(lock_path) =~ "Use concise sentences."
  end

  defp initialize_repository(root) do
    git!(root, ["init", "-q"])
    git!(root, ["config", "user.email", "context@example.com"])
    git!(root, ["config", "user.name", "Context Test"])

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
    File.write!(Path.join([root, "docs", "guide.md"]), "Create an Account.")
    git!(root, ["add", "."])
    git!(root, ["commit", "-q", "-m", "init"])
  end

  defp git!(root, args) do
    {_output, 0} =
      MuonTrap.cmd("git", ["-C", root | args], stderr_to_stdout: true, into: "")
  end
end
