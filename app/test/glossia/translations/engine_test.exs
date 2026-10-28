defmodule Glossia.Translations.EngineTest do
  use ExUnit.Case, async: true
  use Mimic

  import ExUnit.CaptureLog

  alias Glossia.Accounts.Account
  alias Glossia.Translations
  alias Glossia.Translations.Context
  alias Glossia.Translations.Engine
  alias Glossia.Translations.Validate
  alias Glossia.TranslationStubs

  defp work_item(overrides) do
    Map.merge(
      %{
        source_abs: nil,
        output_abs: "/repo/docs/i18n/es/guide.md",
        output_path: "docs/i18n/es/guide.md",
        locale: "es",
        language: "Spanish",
        source_language: "en",
        format: "markdown",
        frontmatter_mode: :preserve,
        preserve: [],
        prompt: nil,
        check_cmd: nil,
        check_cmds: %{},
        validation: nil,
        retries: 2,
        model: "translator",
        context_body: "",
        locale_override_body: "",
        server_context: Context.empty_bundle("es")
      },
      overrides
    )
  end

  defp stub_stream(fun), do: Mimic.stub(Translations, :translate_stream, fun)

  defp translated(text),
    do:
      {:ok,
       %{text: text, model: "anthropic/claude", provider: "anthropic", model_handle: "translator"}}

  describe "strip_structured_code_fence/2" do
    test "strips a fence around structured output" do
      assert Engine.strip_structured_code_fence("json", "```json\n{\"a\":1}\n```") == "{\"a\":1}"
      assert Engine.strip_structured_code_fence("yaml", "```\na: 1\n```") == "a: 1"
    end

    test "leaves prose formats untouched" do
      assert Engine.strip_structured_code_fence("markdown", "```\ncode\n```") == "```\ncode\n```"
    end

    test "leaves partially/unfenced structured output untouched" do
      assert Engine.strip_structured_code_fence("json", "{\"a\":1}") == "{\"a\":1}"

      assert Engine.strip_structured_code_fence("json", "```json\n{\"a\":1}") ==
               "```json\n{\"a\":1}"
    end
  end

  describe "reassemble/2" do
    test "reattaches frontmatter, or emits just the fence for empty bodies" do
      assert Engine.reassemble(nil, "body") == "body"
      assert Engine.reassemble("---\nx: 1\n---", "body") == "---\nx: 1\n---\nbody"
      assert Engine.reassemble("---\nx: 1\n---", "   ") == "---\nx: 1\n---\n"
    end
  end

  describe "prepare/2" do
    test "splits markdown frontmatter only in preserve mode" do
      assert {"---\nt: 1\n---", "Body"} =
               Engine.prepare(work_item(%{}), "---\nt: 1\n---\nBody")

      assert {nil, "---\nt: 1\n---\nBody"} =
               Engine.prepare(work_item(%{frontmatter_mode: :translate}), "---\nt: 1\n---\nBody")

      assert {nil, "raw"} = Engine.prepare(work_item(%{format: "text"}), "raw")
    end
  end

  test "fails closed when server context was not attached" do
    item = work_item(%{}) |> Map.delete(:server_context)

    assert {:error, :server_context_missing} =
             Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)
  end

  describe "apply_item/4" do
    @tag :tmp_dir
    test "translates glossary sentences without corrupting nested Markdown", %{tmp_dir: dir} do
      source = Path.join(dir, "glossary.md")

      File.write!(
        source,
        "---\ntitle: Glossary\n---\n" <>
          "**Missing `source`.** Every term needs a non-empty one.\n\n" <>
          "**Duplicate `id`.** Every id must be unique.\n"
      )

      stub_stream(fn _account, payload, _on_event ->
        translated(
          TranslationStubs.respond(payload, fn template ->
            template
            |> String.replace("Missing", "Falta")
            |> String.replace("Duplicate", "Duplicado")
            |> String.replace("Every term needs a non-empty one.", "Cada término necesita uno.")
            |> String.replace("Every id must be unique.", "Cada id debe ser único.")
          end)
        )
      end)

      validate = fn output, original ->
        Glossia.Translations.Validate.validate_output(dir, "markdown", output, original)
      end

      assert {:ok, result} =
               Engine.apply_item(
                 work_item(%{source_abs: source, retries: 0}),
                 %Account{id: 1},
                 fn _ -> :ok end,
                 validate
               )

      assert result.text ==
               "---\ntitle: Glossary\n---\n" <>
                 "**Falta `source`.** Cada término necesita uno.\n\n" <>
                 "**Duplicado `id`.** Cada id debe ser único.\n"
    end

    @tag :tmp_dir
    test "translates the body and reattaches preserved frontmatter", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")
      File.write!(source, "---\ntitle: Hi\n---\nHello, world.")

      stub_stream(fn %Account{}, payload, on_event ->
        assert payload["segment_kind"] == "markdown_units"
        assert TranslationStubs.unit_texts(payload) == ["Hello, world."]
        assert payload["frontmatter_preserved"] == true
        on_event.(:turn_start)
        translated(TranslationStubs.respond(payload, fn "Hello, world." -> "Hola, mundo." end))
      end)

      assert {:ok, result} =
               Engine.apply_item(work_item(%{source_abs: source}), %Account{id: 1}, fn _ ->
                 :ok
               end)

      assert result.text == "---\ntitle: Hi\n---\nHola, mundo."
      assert result.output_path == "docs/i18n/es/guide.md"
    end

    @tag :tmp_dir
    test "translates Markdown sentence by sentence and keeps every other byte", %{tmp_dir: dir} do
      source = Path.join(dir, "cache.md")

      body = """
      # Cache {#cache}

      Run `tuist cache` on [Tuist Runners](https://tuist.dev/runners) to get warm hits.

      <.home_card
        title="Module cache"
        link="/guides/features/cache/module-cache"
      />

      > [!TIP]
      > See the <.localized_link href="/cli/release-channels">release channels</.localized_link>.
      """

      File.write!(source, "---\ntitle: Cache\n---\n" <> body)
      test_pid = self()

      stub_stream(fn _account, payload, _on_event ->
        send(test_pid, {:payload, payload})

        translated(
          TranslationStubs.respond(payload, fn
            "Cache <g1/>" ->
              "Caché <g1/>"

            "Run <g1/> on <g2>Tuist Runners</g2> to get warm hits." ->
              "En <g2>Tuist Runners</g2>, ejecuta <g1/> para obtener aciertos."

            "Module cache" ->
              "Caché de módulos"

            "See the <g1/>release channels<g2/>." ->
              "Consulta los <g1/>canales de lanzamiento<g2/>."
          end)
        )
      end)

      assert {:ok, result} =
               Engine.apply_item(work_item(%{source_abs: source}), %Account{id: 1}, fn _ ->
                 :ok
               end)

      assert result.text ==
               "---\ntitle: Cache\n---\n" <>
                 """
                 # Caché {#cache}

                 En [Tuist Runners](https://tuist.dev/runners), ejecuta `tuist cache` para obtener aciertos.

                 <.home_card
                   title="Caché de módulos"
                   link="/guides/features/cache/module-cache"
                 />

                 > [!TIP]
                 > Consulta los <.localized_link href="/cli/release-channels">canales de lanzamiento</.localized_link>.
                 """

      # One request carries the whole document as read-only context.
      assert_received {:payload, payload}
      refute_received {:payload, _another}
      assert payload["source_context"] == String.trim_trailing(body)
    end

    @tag :tmp_dir
    test "resends only the Markdown units that came back invalid", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")
      File.write!(source, "Read the [guide](https://example.com).\n\nRun `mix test` now.\n")
      test_pid = self()

      stub_stream(fn _account, payload, _on_event ->
        send(test_pid, {:request, TranslationStubs.unit_texts(payload), payload["last_error"]})

        translated(
          TranslationStubs.respond(payload, fn
            "Read the <g1>guide</g1>." ->
              "Lee la <g1>guía</g1>."

            "Run <g1/> now." ->
              if payload["last_error"], do: "Ejecuta <g1/> ahora.", else: "Ejecuta ahora."
          end)
        )
      end)

      assert {:ok, result} =
               Engine.apply_item(work_item(%{source_abs: source}), %Account{id: 1}, fn _ ->
                 :ok
               end)

      assert result.text == "Lee la [guía](https://example.com).\n\nEjecuta `mix test` ahora.\n"

      assert_received {:request, ["Read the <g1>guide</g1>.", "Run <g1/> now."], nil}
      assert_received {:request, ["Run <g1/> now."], error}
      assert error == "every tag must appear exactly once: <g1/> (u2)"
      refute_received {:request, _texts, _error}
    end

    @tag :tmp_dir
    test "escapes a translation that would add Markdown structure without asking again", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "guide.md")
      File.write!(source, "Intro.\n\nNumbers matter.\n")
      test_pid = self()

      stub_stream(fn _account, payload, _on_event ->
        send(test_pid, :request)

        translated(
          TranslationStubs.respond(payload, fn
            "Intro." -> "# Introducción"
            "Numbers matter." -> "1. Los números importan."
          end)
        )
      end)

      assert {:ok, result} =
               Engine.apply_item(work_item(%{source_abs: source}), %Account{id: 1}, fn _ ->
                 :ok
               end)

      assert result.text == "\\# Introducción\n\n1\\. Los números importan.\n"
      assert_received :request
      refute_received :request
    end

    @tag :tmp_dir
    test "fails a Markdown file whose units stay invalid after every round", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")
      File.write!(source, "Run `mix test` now.\n")
      test_pid = self()

      stub_stream(fn _account, payload, _on_event ->
        send(test_pid, :request)
        translated(TranslationStubs.respond(payload, fn _text -> "Ejecuta ahora." end))
      end)

      item = work_item(%{source_abs: source, retries: 0})

      assert {:error, {:validation_failed, "every tag must appear exactly once: <g1/> (u1)"}} =
               Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)

      for _round <- 1..3, do: assert_received(:request)
      refute_received :request
    end

    @tag :tmp_dir
    test "rejects empty Markdown output before it can be written", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")
      File.write!(source, "# Retry setup\n\nCheck the configured model before retrying.")

      stub_stream(fn _account, _payload, _on_event -> translated("") end)

      item = work_item(%{source_abs: source, retries: 0})

      assert {:error, {:validation_failed, message}} =
               Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)

      assert message == "translated output was empty for non-empty source content (u1, u2)"
    end

    @tag :tmp_dir
    test "retries an empty frontmatter response with a complete-block instruction", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "guide.md")
      File.write!(source, "%{\n  title: \"Hello\"\n}\n---\n\nBody")

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])

        case {payload["segment_kind"], payload["last_error"]} do
          {"frontmatter_text_literals", nil} ->
            translated("")

          {"frontmatter_text_literals", error} ->
            assert error =~ "translated output was empty for non-empty frontmatter"
            assert error =~ "return the complete frontmatter block"
            translated(JSON.encode!(["Hola"]))

          {"markdown_units", _error} ->
            translated(TranslationStubs.respond(payload, fn "Body" -> "Cuerpo" end))
        end
      end)

      item = work_item(%{source_abs: source, frontmatter_mode: :translate, retries: 0})

      log =
        capture_log([level: :warning], fn ->
          assert {:ok, %{text: "%{title: \"Hola\"}\n---\n\nCuerpo"}} =
                   Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)
        end)

      assert log =~ "Translation model returned empty output"
      assert log =~ ~s("segment_kind":"frontmatter_text_literals")
      assert log =~ ~s("segment_attempt":1)
      assert log =~ ~s("source_bytes":9)

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)

      assert Enum.map(calls, &{&1["segment_kind"], &1["last_error"]}) == [
               {"frontmatter_text_literals", nil},
               {"frontmatter_text_literals",
                "translated output was empty for non-empty frontmatter; return the complete frontmatter block with its syntax and delimiters intact"},
               {"markdown_units", nil}
             ]
    end

    @tag :tmp_dir
    test "preserves NimblePublisher frontmatter and translates a long body in segments", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "guide.md")

      first = String.duplicate("First paragraph remains together. ", 90)
      second = String.duplicate("Second paragraph remains together. ", 90)

      File.write!(
        source,
        "%{\n  title: \"Hello\",\n  date: ~D[2026-02-03]\n}\n---\n\n# Guide\n\n#{first}\n\n## Next\n\n#{second}"
      )

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])

        translated(
          TranslationStubs.respond(payload, fn text ->
            text
            |> String.replace("First", "Primero")
            |> String.replace("Second", "Segundo")
            |> String.replace("Guide", "Guía")
            |> String.replace("Next", "Siguiente")
          end)
        )
      end)

      assert {:ok, result} =
               Engine.apply_item(work_item(%{source_abs: source}), %Account{id: 1}, fn _ ->
                 :ok
               end)

      assert [first_call, second_call] = payloads |> Elixir.Agent.get(&Enum.reverse/1)
      assert Enum.all?([first_call, second_call], &(&1["segment_count"] == 2))
      assert Enum.all?([first_call, second_call], &(&1["segment_kind"] == "markdown_units"))

      refute Enum.any?(
               [first_call, second_call],
               &String.contains?(&1["source_content"], ~s(title: "Hello"))
             )

      # Every batch reads the document around it, and a later batch also sees
      # the most recent passages already translated, so terminology stays
      # consistent.
      assert first_call["source_context"] =~ "## Next"
      refute first_call["source_context"] =~ "Already translated"
      assert second_call["source_context"] =~ "Already translated earlier in this document"
      assert second_call["source_context"] =~ "Next\n=> Siguiente"

      assert result.text =~ "\n# Guía\n"
      assert result.text =~ "\n## Siguiente\n"
      assert result.text =~ "Primero paragraph remains together."
      assert result.text =~ "Segundo paragraph remains together."
    end

    @tag :tmp_dir
    test "passes only segment-relevant server glossary to the model", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.txt")

      File.write!(
        source,
        String.duplicate("Configure the Account. ", 220) <>
          "\n\n" <> String.duplicate("Open the Project. ", 220)
      )

      bundle = %{
        Context.empty_bundle("es")
        | voice: nil,
          glossary: [
            %{
              id: "account",
              term: "Account",
              translation: "Cuenta",
              definition: nil,
              case_sensitive: true
            },
            %{
              id: "project",
              term: "Project",
              translation: "Proyecto",
              definition: nil,
              case_sensitive: true
            }
          ]
      }

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])
        translated("translated segment #{payload["segment_index"]}")
      end)

      item = work_item(%{source_abs: source, format: "text", server_context: bundle})
      assert {:ok, _result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)

      [first, second] = payloads |> Elixir.Agent.get(&Enum.reverse/1)
      assert first["server_context_body"] =~ ~s("Account" → "Cuenta")
      refute first["server_context_body"] =~ ~s("Project" → "Proyecto")
      assert second["server_context_body"] =~ ~s("Project" → "Proyecto")
      refute second["server_context_body"] =~ ~s("Account" → "Cuenta")
    end

    @tag :tmp_dir
    test "keeps glossary selection aligned when preservation is disabled", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.txt")
      File.write!(source, "Use `Account` here.")

      bundle = %{
        Context.empty_bundle("es")
        | glossary: [
            %{
              id: "account",
              term: "Account",
              translation: "Cuenta",
              definition: nil,
              case_sensitive: true
            }
          ]
      }

      stub_stream(fn _account, payload, _on_event ->
        assert payload["source_content"] == "Use `Account` here."
        assert payload["server_context_body"] =~ ~s("Account" → "Cuenta")
        translated("Usa `Cuenta` aquí.")
      end)

      item =
        work_item(%{
          source_abs: source,
          format: "text",
          preserve: ["none"],
          server_context: bundle
        })

      assert {:ok, _result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)
    end

    @tag :tmp_dir
    test "reports context clipping once per item, including across retries", %{tmp_dir: dir} do
      source = Path.join(dir, "dense.txt")

      entries =
        for index <- 1..60 do
          %{
            id: "term-#{index}",
            term: "Term#{index}",
            translation: "Target#{index}",
            definition: nil,
            case_sensitive: true
          }
        end

      File.write!(source, Enum.map_join(entries, " ", & &1.term))
      bundle = %{Context.empty_bundle("es") | glossary: entries}

      stub_stream(fn _account, payload, _on_event ->
        if payload["last_error"], do: translated("good"), else: translated("bad")
      end)

      parent = self()

      on_event = fn
        {:context_budget, budget} -> send(parent, {:context_budget, budget})
        _event -> :ok
      end

      validate = fn text, _source ->
        if text == "good", do: :ok, else: {:error, "try again"}
      end

      item =
        work_item(%{
          source_abs: source,
          format: "text",
          retries: 1,
          server_context: bundle
        })

      assert {:ok, %{text: "good"}} =
               Engine.apply_item(item, %Account{id: 1}, on_event, validate)

      assert_receive {:context_budget,
                      %{
                        segments_with_glossary_omissions: 1,
                        glossary_matched: 60,
                        glossary_included: 50,
                        glossary_omitted: 10,
                        glossary_definitions_omitted: 0,
                        voice_truncated: false
                      }}

      refute_receive {:context_budget, _budget}
    end

    @tag :tmp_dir
    test "translates NimblePublisher frontmatter separately from segmented body content", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "guide.md")

      first = String.duplicate("First paragraph remains together. ", 90)
      second = String.duplicate("Second paragraph remains together. ", 90)

      File.write!(
        source,
        "%{\n  title: \"Hello\"\n}\n---\n\n#{first}\n\n#{second}"
      )

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])

        case payload["segment_kind"] do
          "frontmatter_text_literals" ->
            assert payload["segment_index"] == 1
            assert JSON.decode!(payload["source_content"]) == ["Hello"]
            translated(JSON.encode!(["Hola"]))

          "markdown_units" ->
            translated(
              TranslationStubs.respond(payload, fn _text ->
                "Cuerpo #{payload["segment_index"]}"
              end)
            )
        end
      end)

      item = work_item(%{source_abs: source, frontmatter_mode: :translate})
      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)

      assert Enum.map(calls, & &1["segment_kind"]) == [
               "frontmatter_text_literals",
               "markdown_units",
               "markdown_units"
             ]

      assert Enum.all?(calls, &(&1["segment_count"] == 3))

      assert result.text ==
               "%{title: \"Hola\"}\n---\n\nCuerpo 2 \n\nCuerpo 3 "
    end

    @tag :tmp_dir
    test "rebuilds translated NimblePublisher values without allowing model syntax changes", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "guide.md")

      File.write!(
        source,
        "%{\n  title: \"Hello\",\n  summary: \"A summary\",\n  date: ~D[2026-02-03],\n  slug: \"guide\",\n  author: \"pepicrft\"\n}\n---\n\nBody"
      )

      stub_stream(fn _account, payload, _on_event ->
        case payload["segment_kind"] do
          "frontmatter_text_literals" ->
            assert JSON.decode!(payload["source_content"]) == ["Hello", "A summary"]
            translated(JSON.encode!(["Hola", "Un resumen"]))

          "markdown_units" ->
            translated(TranslationStubs.respond(payload, fn "Body" -> "Cuerpo" end))
        end
      end)

      assert {:ok, result} =
               Engine.apply_item(
                 work_item(%{source_abs: source, frontmatter_mode: :translate}),
                 %Account{id: 1},
                 fn _ -> :ok end
               )

      assert result.text ==
               "%{title: \"Hola\", summary: \"Un resumen\", date: ~D[2026-02-03], slug: \"guide\", author: \"pepicrft\"}\n---\n\nCuerpo"
    end

    @tag :tmp_dir
    test "reconstructs Apple catalogs from translated values without changing keys or syntax", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "Localizable.strings")

      content = ~S"""
      /* Preserve "a" = "comment"; */
      "%@ of %@ files" = "%1$@ of %2$@ files";
      "Title" /* key */ = /* value */ "Choose Files" /* end */;
      "Speech" = "Say \"hello\"\nC:\\drafts";
      "Direction" = "\U2066path\U2069";
      "One" = "One";
      "Two" = "Two";
      "Three" = "Three";
      "Four" = "Four";
      // A second batch, including non-ASCII before its value.
      "日本語" = "Last value";
      "Empty" = "";
      """

      File.write!(source, content)

      translations = %{
        "%1$@ of %2$@ files" => "%2$@ archivos de %1$@",
        "Choose Files" => "Elegir \"archivos\"",
        "Say \"hello\"\nC:\\drafts" => "Di \"hola\"\nC:\\borradores",
        "\u2066path\u2069" => "\u2066ruta\u2069",
        "Last value" => "Último valor"
      }

      stub_stream(fn _account, payload, _on_event ->
        values = JSON.decode!(payload["source_content"])
        translated(JSON.encode!(Enum.map(values, &Map.get(translations, &1, &1))))
      end)

      assert {:ok, result} =
               Engine.apply_item(
                 work_item(%{source_abs: source, format: "text"}),
                 %Account{id: 1},
                 fn _ -> :ok end
               )

      assert result.text == """
             /* Preserve "a" = "comment"; */
             "%@ of %@ files" = "%2$@ archivos de %1$@";
             "Title" /* key */ = /* value */ "Elegir \\"archivos\\"" /* end */;
             "Speech" = "Di \\"hola\\"\\nC:\\\\borradores";
             "Direction" = "\u2066ruta\u2069";
             "One" = "One";
             "Two" = "Two";
             "Three" = "Three";
             "Four" = "Four";
             // A second batch, including non-ASCII before its value.
             "日本語" = "Último valor";
             "Empty" = "";
             """
    end

    @tag :tmp_dir
    test "changes only translated Apple values, preserving original escapes and file bytes", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "Localizable.strings")

      content =
        "\uFEFF/* Keep layout */\r\n" <>
          ~S("Été" /* key */ = "Summer"; // trailing comment) <>
          "\r\n\r\n\t" <> ~S("Brand" = "\U0047lossia \U2066path\U2069";)

      File.write!(source, content)

      stub_stream(fn _account, payload, _on_event ->
        assert payload["segment_kind"] == "native_text_literals"
        assert JSON.decode!(payload["source_content"]) == ["Summer", "Glossia \u2066path\u2069"]
        translated(JSON.encode!(["Été", "Glossia \u2066path\u2069"]))
      end)

      assert {:ok, result} =
               Engine.apply_item(
                 work_item(%{source_abs: source, format: "text"}),
                 %Account{id: 1},
                 fn _ -> :ok end
               )

      assert result.text ==
               "\uFEFF/* Keep layout */\r\n" <>
                 ~S("Été" /* key */ = "Été"; // trailing comment) <>
                 "\r\n\r\n\t" <> ~S("Brand" = "\U0047lossia \U2066path\U2069";)
    end

    @tag :tmp_dir
    test "reconstructs Android XML with resource escaping and original attributes", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "strings.xml")

      File.write!(source, ~S"""
      <?xml version="1.0" encoding="utf-8"?>
      <resources>
        <!-- Keep <string name="example">comments</string> -->
        <string name="title" formatted="false">"Choose &amp; open \&#x22;files\&#34;"</string>
        <string translatable="false" name="brand">"Glossia"</string>
        <string formatted="false" name="progress">"%1$s of %2$d \u2066files\u2069"</string>
      </resources>
      """)

      stub_stream(fn _account, payload, _on_event ->
        values = JSON.decode!(payload["source_content"])

        translated(
          JSON.encode!(
            Enum.map(values, fn
              "Choose & open \"files\"" -> "Elige & abre \"<archivos>\"\r\notra línea\\r"
              "%1$s of %2$d \u2066files\u2069" -> "%2$d archivos de %1$s \u2066archivos\u2069"
            end)
          )
        )
      end)

      assert {:ok, result} =
               Engine.apply_item(
                 work_item(%{source_abs: source, format: "text"}),
                 %Account{id: 1},
                 fn _ -> :ok end
               )

      assert result.text == """
             <?xml version="1.0" encoding="utf-8"?>
             <resources>
               <!-- Keep <string name="example">comments</string> -->
               <string name="title" formatted="false">"Elige &amp; abre \\"&lt;archivos&gt;\\"\\u000d\\notra línea\\\\r"</string>
               <string translatable="false" name="brand">"Glossia"</string>
               <string formatted="false" name="progress">"%2$d archivos de %1$s \u2066archivos\u2069"</string>
             </resources>
             """
    end

    @tag :tmp_dir
    test "rejects invalid native value responses before reconstructing a catalog", %{tmp_dir: dir} do
      source = Path.join(dir, "Localizable.strings")
      File.write!(source, ~S("Stable key" = "%1$@ has %2$lld \U2066files\U2069";))

      for response <- [
            ~s(["%1$@ tiene %2$d \u2066archivos\u2069"]),
            ~s(["%1$@ tiene %2$lld archivos"]),
            JSON.encode!(["%1$@ tiene %2$lld \u2069archivos\u2066"]),
            ~s(["%1$@ tiene %2$lld \u2066archivos\u2069", "extra"]),
            ~s([""]),
            ~s([null]),
            "\"Clave traducida\" = \"contenido\";"
          ] do
        stub_stream(fn _account, _payload, _on_event -> translated(response) end)

        assert {:error, {:validation_failed, message}} =
                 Engine.apply_item(
                   work_item(%{source_abs: source, format: "text", retries: 0}),
                   %Account{id: 1},
                   fn _ -> :ok end
                 )

        assert message =~ "native text-literal response"
      end
    end

    @tag :tmp_dir
    test "keeps protected variables and URLs in their own native resource value", %{tmp_dir: dir} do
      source = Path.join(dir, "Localizable.strings")
      File.write!(source, ~S("welcome" = "Welcome {name}"; "help" = "Open https://example.org";))

      for response <- [
            ["Bienvenido", "Abre {name} https://example.org"],
            ["Bienvenido {name} https://example.org", "Abre"],
            ["Bienvenido {name} {extra}", "Abre https://example.org"]
          ] do
        stub_stream(fn _account, _payload, _on_event -> translated(JSON.encode!(response)) end)

        assert {:error, {:validation_failed, message}} =
                 Engine.apply_item(
                   work_item(%{source_abs: source, format: "text", retries: 0}),
                   %Account{id: 1},
                   fn _ -> :ok end
                 )

        assert message =~ "native text-literal response"
      end

      stub_stream(fn _account, _payload, _on_event ->
        translated(JSON.encode!(["Bienvenido {name}", "Abre https://example.org\nNueva línea"]))
      end)

      assert {:ok, result} =
               Engine.apply_item(
                 work_item(%{source_abs: source, format: "text"}),
                 %Account{id: 1},
                 fn _ -> :ok end
               )

      assert result.text ==
               ~S("welcome" = "Bienvenido {name}"; "help" = "Abre https://example.org\nNueva línea";)
    end

    @tag :tmp_dir
    test "fails closed for unsupported native syntax rather than translating resource keys", %{
      tmp_dir: dir
    } do
      stub_stream(fn _account, _payload, _on_event -> translated("unsafe text translation") end)

      for {filename, content} <- [
            {"Localizable.strings", ~S("key" = "\141";)},
            {"Localizable.strings", ~S("key" = "\u2066value\u2069";)},
            {"strings.xml",
             ~S(<resources><string name="key">Unquoted value</string></resources>)},
            {"strings.xml",
             ~S(<resources><string name="key">"\U2066value\U2069"</string></resources>)},
            {"strings.xml", ~S(<resources><string name="key">"line\rbreak"</string></resources>)}
          ] do
        source = Path.join(dir, filename)
        File.write!(source, content)

        assert {:error, {:validation_failed, message}} =
                 Engine.apply_item(
                   work_item(%{source_abs: source, format: "text"}),
                   %Account{id: 1},
                   fn _ -> :ok end
                 )

        assert message == "native catalog source uses unsupported syntax"
      end
    end

    @tag :tmp_dir
    test "preserves dynamic printf arguments and Android date conversions", %{tmp_dir: dir} do
      for {filename, content, original, invalid} <- [
            {"Localizable.strings", ~S("key" = "%*.*f %s";), "%*.*f %s",
             ["%*.*d %s", "%*.*f %1$s", "%s %*.*f"]},
            {"strings.xml", ~S(<resources><string name="key">"%1$tY"</string></resources>),
             "%1$tY", ["%1$tB"]},
            {"strings.xml",
             ~S(<resources><string name="key">"Balance %,d / %(d"</string></resources>),
             "Balance %,d / %(d", ["Saldo %,f / %(d", "Saldo %,d / %(f", "Saldo %d / %(d"]},
            {"Localizable.strings", ~S("key" = "Value %.2f / %04d";), "Value %.2f / %04d",
             ["Valor %f / %04d", "Valor %.3f / %04d", "Valor %.2f / %d", "Valor %.2f / %999999d"]}
          ] do
        source = Path.join(dir, filename)
        File.write!(source, content)

        for value <- invalid do
          stub_stream(fn _account, _payload, _on_event -> translated(JSON.encode!([value])) end)

          assert {:error, {:validation_failed, _message}} =
                   Engine.apply_item(
                     work_item(%{source_abs: source, format: "text", retries: 0}),
                     %Account{id: 1},
                     fn _ -> :ok end
                   )
        end

        stub_stream(fn _account, _payload, _on_event ->
          translated(JSON.encode!(["Traducción " <> original]))
        end)

        assert {:ok, result} =
                 Engine.apply_item(
                   work_item(%{source_abs: source, format: "text"}),
                   %Account{id: 1},
                   fn _ -> :ok end
                 )

        assert result.text == String.replace(content, original, "Traducción " <> original)
      end
    end

    @tag :tmp_dir
    test "validates native escaped placeholders and URLs by their decoded values", %{tmp_dir: dir} do
      stub_stream(fn _account, payload, _on_event -> translated(payload["source_content"]) end)

      for {filename, content} <- [
            {"Localizable.strings",
             ~S("key" = "Hello \U007Bname\U007D at https:\/\/example.org";)},
            {"strings.xml",
             ~S(<resources><string name="key">"Hello \u007bname\u007d"</string></resources>)}
          ] do
        source = Path.join(dir, filename)
        File.write!(source, content)

        validate = fn output, original ->
          Validate.validate_output(dir, "text", output, original, %{source_abs: source})
        end

        assert {:ok, result} =
                 Engine.apply_item(
                   work_item(%{source_abs: source, format: "text", retries: 0}),
                   %Account{id: 1},
                   fn _ -> :ok end,
                   validate
                 )

        assert result.text == content
      end
    end

    @tag :tmp_dir
    test "segments long plain text without relying on a document format", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.txt")

      File.write!(
        source,
        String.duplicate("First paragraph. ", 220) <>
          "\n\n" <> String.duplicate("Second paragraph. ", 220)
      )

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])
        translated("translated segment #{payload["segment_index"]}")
      end)

      item = work_item(%{source_abs: source, format: "text"})
      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)
      assert length(calls) == 2
      assert Enum.all?(calls, &(&1["segment_kind"] == "content"))
      assert Enum.all?(calls, &(&1["segment_count"] == 2))
      assert result.text == "translated segment 1\n\ntranslated segment 2"
    end

    @tag :tmp_dir
    test "translates large catalogs in bounded batches while preserving headers in code",
         %{tmp_dir: dir} do
      source = Path.join(dir, "default.pot")

      header =
        ~s(msgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n)

      entries =
        1..400
        |> Enum.map(fn index ->
          ~s(#: lib/example.ex:#{index}\nmsgid "Message #{index}"\nmsgstr ""\n)
        end)

      content = Enum.join([header | entries], "\n")
      File.write!(source, content)

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])
        translated(payload["source_content"])
      end)

      item = work_item(%{source_abs: source, format: "po"})
      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)
      assert length(calls) == 50
      assert Enum.all?(calls, &(&1["segment_kind"] == "po_text_literals"))
      batches = Enum.map(calls, &JSON.decode!(&1["source_content"]))
      assert Enum.all?(batches, &(length(&1) <= 8))
      literals = List.flatten(batches)
      assert length(literals) == 400
      refute Enum.any?(literals, &String.contains?(&1, "Content-Type:"))
      assert result.text =~ "Language: es"
      assert Enum.any?(literals, &(&1 == "Message 1"))
      assert Enum.any?(literals, &(&1 == "Message 400"))

      # With an echo model the output preserves every source msgid and puts
      # the msgid string into its msgstr (the common template-catalog case).
      assert result.text =~ ~s(msgid "Message 1")
      assert result.text =~ ~s(msgstr "Message 1")
      assert result.text =~ ~s(msgid "Message 400")
    end

    @tag :tmp_dir
    test "surfaces a per-file preservation error when preserved translations skew from source shape",
         %{tmp_dir: dir} do
      # Defensive guard: `Locks.po_status/3` aligns preserved translations to
      # source shape via `Po.align_translations/2` before they reach the
      # engine, so a length skew here would be a programming error, not a
      # data one. Verifying the guard turns that skew into a per-file
      # preservation failure — routed through the existing telemetry — and
      # never a bare-length list that quietly under-counts the rebuild.
      source_path = Path.join(dir, "default.pot")

      content =
        ~s(msgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n\nmsgid "Hello"\nmsgstr ""\n\nmsgid "%d file"\nmsgid_plural "%d files"\nmsgstr[0] ""\nmsgstr[1] ""\n)

      File.write!(source_path, content)

      {:ok, [header_unit, hello_unit, plural_unit]} =
        Glossia.Translations.Po.translation_units(content)

      # Stub echoes the batch back so the stale msgid's translation matches
      # the expected count and clears `distribute_po_translations`; the only
      # skew is the hand-forged preserved plural list, which reaches
      # `units_translations_in_order` and trips its length guard.
      stub_stream(fn _account, payload, _on_event ->
        translated(payload["source_content"])
      end)

      po_diff = %{
        stale_keys: [hello_unit.key],
        preserved: %{
          header_unit.key => ["Language: es\n"],
          plural_unit.key => ["only-one"]
        }
      }

      item = work_item(%{source_abs: source_path, format: "po", po_diff: po_diff})

      assert {:error, {:validation_failed, message}} =
               Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)

      assert message =~ "po text-literal response length"
      assert message =~ "did not match source shape"
      assert message =~ plural_unit.key
    end

    @tag :tmp_dir
    test "ships only stale msgids to the model when a po_diff is present",
         %{tmp_dir: dir} do
      source_path = Path.join(dir, "default.pot")

      content =
        ~s(msgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n\nmsgid "Hello"\nmsgstr ""\n\nmsgid "Goodbye"\nmsgstr ""\n)

      File.write!(source_path, content)

      {:ok, [header_unit, hello_unit, goodbye_unit]} =
        Glossia.Translations.Po.translation_units(content)

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])
        translated(payload["source_content"])
      end)

      # The planner's `po_diff` covers every unit: stale keys carry sources to
      # ship, and preserved carries msgstrs the previous output already has.
      po_diff = %{
        stale_keys: [hello_unit.key],
        preserved: %{
          header_unit.key => ["Language: es\n"],
          goodbye_unit.key => ["Adiós"]
        }
      }

      item = work_item(%{source_abs: source_path, format: "po", po_diff: po_diff})
      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)

      [payload] = Elixir.Agent.get(payloads, &Enum.reverse/1)
      assert payload["segment_kind"] == "po_text_literals"
      # Only the changed msgid's source is shipped — the header and the
      # unchanged "Goodbye" are not.
      assert {:ok, ["Hello"]} = JSON.decode(payload["source_content"])

      # The rebuilt output carries the preserved "Goodbye" translation and the
      # freshly translated "Hello" msgstr (echo model gives back "Hello").
      assert result.text =~ ~s(msgid "Hello")
      assert result.text =~ ~s(msgstr "Hello")
      assert result.text =~ ~s(msgid "Goodbye")
      assert result.text =~ ~s(msgstr "Adiós")
    end

    @tag :tmp_dir
    test "sends msgids intact (including Gettext placeholders) to the model",
         %{tmp_dir: dir} do
      source = Path.join(dir, "default.pot")

      content =
        ~s(msgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n\nmsgid "Hello %{client_name}"\nmsgstr ""\n)

      File.write!(source, content)

      stub_stream(fn _account, payload, _on_event ->
        # The array of strings sent to the model still shows placeholders
        # verbatim so the target-language string can reference them.
        assert payload["segment_kind"] == "po_text_literals"
        assert payload["source_content"] =~ "%{client_name}"
        refute payload["source_content"] =~ "glossia.invalid/protected-token"
        translated(payload["source_content"])
      end)

      item = work_item(%{source_abs: source, format: "po"})
      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)
      # The rebuilt output preserves the source msgid and populates its msgstr
      # with the translated string (echo → same content).
      assert result.text =~ ~s(msgid "Hello %{client_name}")
      assert result.text =~ ~s(msgstr "Hello %{client_name}")
    end

    @tag :tmp_dir
    test "retries with the previous validation error until it passes", %{tmp_dir: dir} do
      source = Path.join(dir, "data.txt")
      File.write!(source, "raw content")

      stub_stream(fn _account, payload, _on_event ->
        if payload["last_error"], do: translated("good"), else: translated("bad")
      end)

      validate = fn text, _ -> if text == "good", do: :ok, else: {:error, "not good enough"} end

      item = work_item(%{source_abs: source, format: "text", frontmatter_mode: :translate})
      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end, validate)
      assert result.text == "good"
    end

    @tag :tmp_dir
    test "strips a structured code fence from the model output", %{tmp_dir: dir} do
      source = Path.join(dir, "data.json")
      File.write!(source, "{}")

      stub_stream(fn _account, _payload, _on_event -> translated("```json\n{\"a\": 1}\n```") end)

      item = work_item(%{source_abs: source, format: "json", frontmatter_mode: :translate})
      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)
      assert result.text == "{\"a\": 1}"
    end

    @tag :tmp_dir
    test "gives up after exhausting retries", %{tmp_dir: dir} do
      source = Path.join(dir, "data.txt")
      File.write!(source, "raw")

      stub_stream(fn _account, _payload, _on_event -> translated("still bad") end)

      item =
        work_item(%{source_abs: source, format: "text", frontmatter_mode: :translate, retries: 1})

      message = "invalid JSON: private output"

      log =
        capture_log(fn ->
          assert {:error, {:validation_failed, ^message}} =
                   Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end, fn _, _ ->
                     {:error, message}
                   end)
        end)

      assert log =~ ~s("validation_code":"json-syntax")
      assert log =~ ~s("validation_stage":"output_validation")
      assert log =~ ~s("document_attempt":1)
      assert log =~ ~s("document_attempt":2)
      assert log =~ ~s("document_attempt_limit":2)
      assert log =~ ~s("retrying":true)
      assert log =~ ~s("retrying":false)
      refute log =~ "private output"
    end
  end
end
