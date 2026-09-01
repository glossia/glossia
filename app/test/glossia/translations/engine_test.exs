defmodule Glossia.Translations.EngineTest do
  use ExUnit.Case, async: true
  use Mimic

  import ExUnit.CaptureLog

  alias Glossia.Accounts.Account
  alias Glossia.Translations
  alias Glossia.Translations.Context
  alias Glossia.Translations.Engine

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
    test "translates the body and reattaches preserved frontmatter", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")
      File.write!(source, "---\ntitle: Hi\n---\nHello, world.")

      stub_stream(fn %Account{}, payload, on_event ->
        assert payload["source_content"] == "Hello, world."
        assert payload["frontmatter_preserved"] == true
        on_event.(:turn_start)
        translated("Hola, mundo.")
      end)

      assert {:ok, result} =
               Engine.apply_item(work_item(%{source_abs: source}), %Account{id: 1}, fn _ ->
                 :ok
               end)

      assert result.text == "---\ntitle: Hi\n---\nHola, mundo."
      assert result.output_path == "docs/i18n/es/guide.md"
    end

    @tag :tmp_dir
    test "rejects empty Markdown output before it can be written", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")
      File.write!(source, "# Retry setup\n\nCheck the configured model before retrying.")

      stub_stream(fn _account, _payload, _on_event -> translated("") end)

      item = work_item(%{source_abs: source, retries: 0})

      assert {:error, {:validation_failed, message}} =
               Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)

      assert message == "translated output was empty for non-empty source content"
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

          {"content", _error} ->
            translated("Cuerpo")
        end
      end)

      item = work_item(%{source_abs: source, frontmatter_mode: :translate, retries: 0})

      log =
        capture_log([level: :warning], fn ->
          assert {:ok, %{text: "%{title: \"Hola\"}\n---\nCuerpo"}} =
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
               {"content", nil}
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
          payload["source_content"]
          |> String.replace("First", "Primero")
          |> String.replace("Second", "Segundo")
          |> String.replace("Guide", "Guía")
          |> String.replace("Next", "Siguiente")
        )
      end)

      assert {:ok, result} =
               Engine.apply_item(work_item(%{source_abs: source}), %Account{id: 1}, fn _ ->
                 :ok
               end)

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)
      assert length(calls) == 2
      assert Enum.all?(calls, &(&1["segment_count"] == 2))
      assert Enum.all?(calls, &(&1["segment_kind"] == "content"))
      refute Enum.any?(calls, &String.contains?(&1["source_content"], ~s(title: "Hello")))

      assert result.text =~ "# Guía"
      assert result.text =~ "## Siguiente"
      assert result.text =~ "Primero paragraph remains together."
      assert result.text =~ "Segundo paragraph remains together."
    end

    @tag :tmp_dir
    test "passes only segment-relevant server terminology to the model", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.txt")

      File.write!(
        source,
        String.duplicate("Configure the Account. ", 220) <>
          "\n\n" <> String.duplicate("Open the Project. ", 220)
      )

      bundle = %{
        Context.empty_bundle("es")
        | voice: nil,
          terminology: [
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
    test "keeps terminology selection aligned when preservation is disabled", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.txt")
      File.write!(source, "Use `Account` here.")

      bundle = %{
        Context.empty_bundle("es")
        | terminology: [
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
      bundle = %{Context.empty_bundle("es") | terminology: entries}

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
                        segments_with_terminology_omissions: 1,
                        terminology_matched: 60,
                        terminology_included: 50,
                        terminology_omitted: 10,
                        terminology_definitions_omitted: 0,
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

          "content" ->
            translated("Cuerpo #{payload["segment_index"]}")
        end
      end)

      item = work_item(%{source_abs: source, frontmatter_mode: :translate})
      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)

      assert Enum.map(calls, & &1["segment_kind"]) == [
               "frontmatter_text_literals",
               "content",
               "content"
             ]

      assert Enum.all?(calls, &(&1["segment_count"] == 3))

      assert result.text ==
               "%{title: \"Hola\"}\n---\nCuerpo 2\n\nCuerpo 3"
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

          "content" ->
            translated("Cuerpo")
        end
      end)

      assert {:ok, result} =
               Engine.apply_item(
                 work_item(%{source_abs: source, frontmatter_mode: :translate}),
                 %Account{id: 1},
                 fn _ -> :ok end
               )

      assert result.text ==
               "%{title: \"Hola\", summary: \"Un resumen\", date: ~D[2026-02-03], slug: \"guide\", author: \"pepicrft\"}\n---\nCuerpo"
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
    test "segments large Gettext catalogs without splitting entries", %{tmp_dir: dir} do
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
      assert length(calls) > 1
      assert Enum.all?(calls, &(&1["segment_count"] == length(calls)))
      assert Enum.all?(calls, &String.ends_with?(&1["source_content"], ~s(msgstr "")))
      assert result.text == String.trim(content)
    end

    @tag :tmp_dir
    test "leaves Gettext identifiers visible for format validation", %{tmp_dir: dir} do
      source = Path.join(dir, "default.pot")

      content =
        ~s(msgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n\nmsgid "Hello %{client_name}"\nmsgstr ""\n)

      File.write!(source, content)

      stub_stream(fn _account, payload, _on_event ->
        assert payload["source_content"] =~ "%{client_name}"
        refute payload["source_content"] =~ "glossia.invalid/protected-token"
        translated(payload["source_content"])
      end)

      item = work_item(%{source_abs: source, format: "po"})
      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)
      assert result.text == String.trim(content)
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
    test "recovers a Markdown structure failure through text markers before splitting blocks", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "guide.md")
      File.write!(source, "[Guide](https://example.com/guide)\n\nParagraph.")

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])

        case String.trim(payload["source_content"]) do
          "[Guide](https://example.com/guide)\n\nParagraph." ->
            translated("Guide\n\nParagraph.")

          marked when is_binary(marked) ->
            assert payload["segment_kind"] == "markdown_text_markers"

            translated(
              "@@GLOSSIA-TEXT-1-START@@Leitfaden@@GLOSSIA-TEXT-1-END@@\n\n" <>
                "@@GLOSSIA-TEXT-2-START@@Absatz.@@GLOSSIA-TEXT-2-END@@"
            )
        end
      end)

      item = work_item(%{source_abs: source, retries: 1})

      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)
      assert result.text == "[Leitfaden](https://example.com/guide)\n\nAbsatz."

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)
      assert Enum.map(calls, & &1["segment_kind"]) == ["content", "markdown_text_markers"]
    end

    @tag :tmp_dir
    test "recovers a structurally invalid Markdown block through text markers", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")
      File.write!(source, "Read [the guide](https://example.com/guide).")

      stub_stream(fn _account, payload, _on_event ->
        if String.contains?(payload["source_content"], "@@GLOSSIA-TEXT-") do
          translated(
            "@@GLOSSIA-TEXT-1-START@@Lee @@GLOSSIA-TEXT-1-END@@" <>
              "@@GLOSSIA-TEXT-2-START@@la guía@@GLOSSIA-TEXT-2-END@@" <>
              "@@GLOSSIA-TEXT-3-START@@.@@GLOSSIA-TEXT-3-END@@"
          )
        else
          translated("Lee la guía.")
        end
      end)

      item = work_item(%{source_abs: source, retries: 0})

      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)
      assert result.text == "Lee [la guía](https://example.com/guide)."
    end

    @tag :tmp_dir
    test "falls back to source blocks when marker recovery is invalid", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")
      File.write!(source, "[Guide](https://example.com/guide)\n\nParagraph.")

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])

        cond do
          payload["segment_kind"] == "markdown_text_markers" ->
            translated("The required recovery markers are absent.")

          String.trim(payload["source_content"]) ==
              "[Guide](https://example.com/guide)\n\nParagraph." ->
            translated("Guide\n\nParagraph.")

          String.trim(payload["source_content"]) == "[Guide](https://example.com/guide)" ->
            translated("[Leitfaden](https://example.com/guide)")

          String.trim(payload["source_content"]) == "Paragraph." ->
            translated("Absatz.")
        end
      end)

      assert {:ok, result} =
               Engine.apply_item(
                 work_item(%{source_abs: source, retries: 1}),
                 %Account{id: 1},
                 fn _ ->
                   :ok
                 end
               )

      assert result.text == "[Leitfaden](https://example.com/guide)\n\nAbsatz."

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)
      assert Enum.count(calls, &(&1["segment_kind"] == "markdown_text_markers")) == 2
    end

    @tag :tmp_dir
    test "recovers a dropped Markdown link through text markers", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")
      File.write!(source, "Read [the guide](https://example.com/guide).")

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])

        case payload["segment_kind"] do
          "markdown_text_markers" ->
            translated(
              "@@GLOSSIA-TEXT-1-START@@Lee @@GLOSSIA-TEXT-1-END@@" <>
                "@@GLOSSIA-TEXT-2-START@@la guía@@GLOSSIA-TEXT-2-END@@" <>
                "@@GLOSSIA-TEXT-3-START@@.@@GLOSSIA-TEXT-3-END@@"
            )

          _ ->
            translated("Lee la guía.")
        end
      end)

      assert {:ok, result} =
               Engine.apply_item(
                 work_item(%{source_abs: source, retries: 0}),
                 %Account{id: 1},
                 fn _ -> :ok end
               )

      assert result.text == "Lee [la guía](https://example.com/guide)."

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)
      assert Enum.map(calls, & &1["segment_kind"]) == ["content", "markdown_text_markers"]
    end

    @tag :tmp_dir
    test "rebuilds Markdown from bounded text-literal batches after every structural recovery fails",
         %{
           tmp_dir: dir
         } do
      source = Path.join(dir, "guide.md")
      File.write!(source, "Read [Guide](https://example.com/guide) now.")

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)
      {:ok, progress} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])

        case payload["segment_kind"] do
          "markdown_text_markers" ->
            translated("The required recovery markers are absent.")

          "markdown_text_literals" ->
            assert JSON.decode!(payload["source_content"]) == ["Read", "Guide", "now."]
            on_event.({:text, "Lies"})
            translated(JSON.encode!(["Lies", "Leitfaden", "jetzt."]))

          _ ->
            translated("Read Guide now.")
        end
      end)

      item = work_item(%{source_abs: source, retries: 0})
      on_event = fn event -> Elixir.Agent.update(progress, &[event | &1]) end

      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, on_event)
      assert result.text == "Lies [Leitfaden](https://example.com/guide) jetzt."

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)
      assert Enum.any?(calls, &(&1["segment_kind"] == "markdown_text_literals"))

      literal_batches =
        calls
        |> Enum.filter(&(&1["segment_kind"] == "markdown_text_literals"))
        |> Enum.map(& &1["source_content"])

      assert literal_batches == [JSON.encode!(["Read", "Guide", "now."])]

      outputs =
        progress
        |> Elixir.Agent.get(&Enum.reverse/1)
        |> Enum.filter(&match?({:segment_output, _}, &1))

      assert outputs == [{:segment_output, "Lies [Leitfaden](https://example.com/guide) jetzt."}]

      progress_events = progress |> Elixir.Agent.get(&Enum.reverse/1)
      refute Enum.any?(progress_events, &match?({:text, _}, &1))
    end

    @tag :tmp_dir
    test "translates large Markdown segments as bounded text-literal batches", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")

      content =
        1..12
        |> Enum.map_join("\n\n", fn index ->
          "Read [guide #{index}](https://example.com/#{index})."
        end)

      File.write!(source, content)
      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])

        case payload["segment_kind"] do
          "markdown_text_literals" ->
            translated =
              payload["source_content"]
              |> JSON.decode!()
              |> Enum.map(&"translated #{&1}")
              |> JSON.encode!()

            translated(translated)

          other ->
            flunk("expected bounded Markdown literal batch, got #{inspect(other)}")
        end
      end)

      assert {:ok, result} =
               Engine.apply_item(work_item(%{source_abs: source}), %Account{id: 1}, fn _ ->
                 :ok
               end)

      assert result.text =~ "[translated guide 1](https://example.com/1)"
      assert result.text =~ "[translated guide 12](https://example.com/12)"

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)
      assert length(calls) > 1
      assert Enum.all?(calls, &(&1["segment_kind"] == "markdown_text_literals"))

      assert Enum.all?(calls, fn payload ->
               payload["source_content"]
               |> JSON.decode!()
               |> length()
               |> Kernel.<=(32)
             end)
    end

    @tag :tmp_dir
    test "masks bare web addresses during batched Markdown text-literal recovery", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "guide.md")
      File.write!(source, "Find details at https://example.com/docs.")

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])

        case payload["segment_kind"] do
          "markdown_text_literals" ->
            [literal] = JSON.decode!(payload["source_content"])
            assert literal =~ "__GLOSSIA_URL_"

            translated(
              JSON.encode!([String.replace(literal, "Find details at", "Weitere Details unter")])
            )

          "markdown_text_markers" ->
            translated("The required recovery markers are absent.")

          _ ->
            translated("Weitere Details.")
        end
      end)

      assert {:ok, result} =
               Engine.apply_item(
                 work_item(%{source_abs: source, retries: 0}),
                 %Account{id: 1},
                 fn _ -> :ok end
               )

      assert result.text == "Weitere Details unter https://example.com/docs."

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)

      assert Enum.any?(calls, &(&1["segment_kind"] == "markdown_text_literals"))

      refute Enum.any?(
               calls,
               fn payload ->
                 payload["segment_kind"] == "markdown_text_literals" and
                   payload["source_content"]
                   |> JSON.decode!()
                   |> Enum.any?(&(&1 =~ "https://example.com/docs"))
               end
             )
    end

    @tag :tmp_dir
    test "bounds individual text-literal recovery", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")

      content =
        1..129
        |> Enum.map_join(" ", fn index ->
          "[Sentence #{index}](https://example.com/#{index})."
        end)

      File.write!(source, content)
      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])

        if payload["segment_kind"] == "markdown_text_markers" do
          translated("The required recovery markers are absent.")
        else
          translated("All sentences.")
        end
      end)

      assert {:error, {:validation_failed, _message}} =
               Engine.apply_item(
                 work_item(%{source_abs: source, retries: 0}),
                 %Account{id: 1},
                 fn _ -> :ok end
               )

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)
      refute Enum.any?(calls, &(&1["segment_kind"] == "markdown_text_literals"))
    end

    @tag :tmp_dir
    test "does not run marker recovery when source prose contains a marker lookalike", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "guide.md")

      File.write!(
        source,
        "Docs mention @@GLOSSIA-TEXT-1-START@@ [the guide](https://example.com/guide)."
      )

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])
        translated("Docs mention the guide.")
      end)

      assert {:error, {:validation_failed, message}} =
               Engine.apply_item(
                 work_item(%{source_abs: source, retries: 0}),
                 %Account{id: 1},
                 fn _ ->
                   :ok
                 end
               )

      assert message =~ "changed the document structure"

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)
      refute Enum.any?(calls, &(&1["segment_kind"] == "markdown_text_markers"))
    end

    @tag :tmp_dir
    test "recovers dense Markdown through markers instead of failing a single source block", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "guide.md")
      File.write!(source, String.duplicate("[Guide](https://example.com/guide) ", 110))

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])

        if payload["segment_kind"] == "markdown_text_markers" do
          translated(payload["source_content"])
        else
          translated("Guide")
        end
      end)

      assert {:ok, result} =
               Engine.apply_item(
                 work_item(%{source_abs: source, retries: 0}),
                 %Account{id: 1},
                 fn _ ->
                   :ok
                 end
               )

      assert result.text =~ "[Guide](https://example.com/guide)"

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)
      assert Enum.any?(calls, &(&1["segment_kind"] == "markdown_text_markers"))
    end

    @tag :tmp_dir
    test "returns a marker recovery provider error without trying source blocks", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")
      File.write!(source, "Read [the guide](https://example.com/guide).")

      stub_stream(fn _account, payload, _on_event ->
        if payload["segment_kind"] == "markdown_text_markers" do
          {:error, :provider_timeout}
        else
          translated("Read the guide.")
        end
      end)

      assert {:error, {:llm_failed, :provider_timeout}} =
               Engine.apply_item(
                 work_item(%{source_abs: source, retries: 0}),
                 %Account{id: 1},
                 fn _ ->
                   :ok
                 end
               )
    end

    @tag :tmp_dir
    test "reassembles Markdown structure while keeping placeholders opaque", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "guide.md")

      File.write!(
        source,
        "Visit [Glossia](https://glossia.ai/{locale}) and run `mix test`."
      )

      stub_stream(fn _account, payload, _on_event ->
        # The source tree owns link destinations and code. Only the placeholder
        # inside the destination is opaque to the model.
        assert payload["source_content"] =~ "https://glossia.ai"
        refute payload["source_content"] =~ "{locale}"
        assert payload["source_content"] =~ "`mix test`"
        assert payload["source_content"] =~ ~r/\{glossia_protected_[a-f0-9]{12}_\d+\}/

        translated(String.replace(payload["source_content"], "Visit", "Visita"))
      end)

      assert {:ok, result} =
               Engine.apply_item(
                 work_item(%{source_abs: source}),
                 %Account{id: 1},
                 fn _ -> :ok end
               )

      assert result.text ==
               "Visita [Glossia](https://glossia.ai/{locale}) and run `mix test`."
    end

    @tag :tmp_dir
    test "keeps repeated web addresses visible to the model", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")

      File.write!(
        source,
        "Compare [Anthropic](https://anthropic.com) with [Claude](https://anthropic.com)."
      )

      stub_stream(fn _account, payload, _on_event ->
        assert length(Regex.scan(~r/https:\/\/anthropic\.com/, payload["source_content"])) == 2

        translated(
          payload["source_content"]
          |> String.replace("Compare", "Compara")
          |> String.replace(" with ", " con ")
        )
      end)

      assert {:ok, result} =
               Engine.apply_item(
                 work_item(%{source_abs: source}),
                 %Account{id: 1},
                 fn _ -> :ok end
               )

      assert result.text ==
               "Compara [Anthropic](https://anthropic.com) con [Claude](https://anthropic.com)."
    end

    @tag :tmp_dir
    test "rejects a protected marker copied into another segment", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")

      File.write!(
        source,
        "{name} " <>
          String.duplicate("First paragraph remains together. ", 180) <>
          "\n\n" <> String.duplicate("Second paragraph remains together. ", 180)
      )

      {:ok, markers} = Elixir.Agent.start_link(fn -> %{} end)

      stub_stream(fn _account, payload, _on_event ->
        case payload["segment_index"] do
          1 ->
            [marker] =
              Regex.run(
                ~r/\{glossia_protected_[a-f0-9]{12}_\d+\}/,
                payload["source_content"]
              )

            Elixir.Agent.update(markers, &Map.put(&1, :copied, marker))
            translated(payload["source_content"])

          2 ->
            marker = Elixir.Agent.get(markers, & &1.copied)
            translated(payload["source_content"] <> " " <> marker)
        end
      end)

      item = work_item(%{source_abs: source, retries: 0})

      assert {:error, {:validation_failed, message}} =
               Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)

      assert message =~ "copied byte-for-byte exactly once"
      assert message =~ "glossia_protected"
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

      assert {:error, {:validation_failed, "nope"}} =
               Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end, fn _, _ ->
                 {:error, "nope"}
               end)
    end

    @tag :tmp_dir
    test "returns a source-block recovery provider error", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")

      File.write!(
        source,
        "@@GLOSSIA-TEXT-1-START@@ [Guide](https://example.com/guide)\n\nParagraph."
      )

      stub_stream(fn _account, payload, _on_event ->
        if String.contains?(payload["source_content"], "\n\n") do
          translated("Guide\n\nParagraph.")
        else
          {:error, :provider_timeout}
        end
      end)

      assert {:error, {:llm_failed, :provider_timeout}} =
               Engine.apply_item(
                 work_item(%{source_abs: source, retries: 0}),
                 %Account{id: 1},
                 fn _ ->
                   :ok
                 end
               )
    end

    @tag :tmp_dir
    test "retranslates only the segment that lost a protected marker", %{tmp_dir: dir} do
      source = Path.join(dir, "links.md")

      first = String.duplicate("First paragraph stays together. ", 90)
      second = String.duplicate("Second paragraph stays together. ", 80)

      File.write!(
        source,
        "#{first}\n\nSee [the report]({report_url}) for details.\n\n#{second}"
      )

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])
        content = payload["source_content"]

        marker =
          case Regex.run(~r/\{glossia_protected_[a-f0-9]{12}_\d+\}/, content) do
            [marker] -> marker
            nil -> nil
          end

        cond do
          # The first attempt on the segment holding the link removes the link
          # entirely. The model keeps the rest of this segmented response.
          is_nil(marker) ->
            translated(content)

          Enum.count(Elixir.Agent.get(payloads, & &1), &(&1["source_content"] == content)) == 1 ->
            translated(Regex.replace(~r/\[the report\]\([^)]*\)/, content, "the report"))

          true ->
            translated(
              content
              |> String.replace("See [the report]", "Consulta [el informe]")
              |> String.replace("for details.", "para más detalles.")
            )
        end
      end)

      item = work_item(%{source_abs: source, frontmatter_mode: :translate})

      {:ok, events} = Elixir.Agent.start_link(fn -> [] end)
      on_event = fn event -> Elixir.Agent.update(events, &[event | &1]) end

      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, on_event)
      assert result.text =~ "{report_url}"

      # Progress folds `segment_output` into the item's completed text, so the
      # rejected attempt must not announce output it is about to discard.
      outputs =
        events
        |> Elixir.Agent.get(&Enum.reverse/1)
        |> Enum.flat_map(fn
          {:segment_output, text} -> [text]
          _ -> []
        end)

      refute Enum.any?(outputs, &String.contains?(&1, "the report for details"))

      calls = Elixir.Agent.get(payloads, &Enum.reverse/1)

      # The valid first segment was left alone, and the invalid Markdown
      # segment was retried once through the marker-based recovery path.
      assert length(calls) == 3
      assert Enum.any?(calls, &(&1["segment_kind"] == "markdown_text_markers"))

      retry = Enum.find(calls, &(&1["last_error"] not in [nil, ""]))
      assert retry["last_error"] =~ "changed the document structure"
    end

    @tag :tmp_dir
    test "recovers a dropped Markdown link without retranslating prior segments", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "links.md")
      first = String.duplicate("First paragraph remains together. ", 130)
      third = String.duplicate("Third paragraph remains together. ", 130)

      File.write!(
        source,
        "#{first}\n\nSee [the report]({report_url}) for details.\n\n#{third}"
      )

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])

        if payload["source_content"] =~ "{glossia_protected_" do
          translated(
            Regex.replace(~r/\[the report\]\([^)]*\)/, payload["source_content"], "the report")
          )
        else
          translated(payload["source_content"])
        end
      end)

      item = work_item(%{source_abs: source, frontmatter_mode: :translate, retries: 2})

      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)
      assert result.text =~ "{report_url}"

      calls = payloads |> Elixir.Agent.get(&Enum.reverse/1)
      assert Enum.count(calls, &(&1["segment_index"] == 1)) == 1
      assert Enum.count(calls, &(&1["segment_index"] == 2)) == 2
      assert Enum.at(calls, 2)["last_error"] =~ "changed the document structure"
    end

    @tag :tmp_dir
    test "keeps web addresses visible to the model and validates the returned address", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "links.md")
      File.write!(source, "See [the report](https://example.com/report) for details.")

      stub_stream(fn _account, payload, _on_event ->
        assert payload["source_content"] =~ "https://example.com/report"
        refute payload["source_content"] =~ "GLOSSIA_URL"

        translated("Consulta [el informe](https://example.com/report) para más detalles.")
      end)

      item = work_item(%{source_abs: source, frontmatter_mode: :translate})

      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)
      assert result.text =~ "https://example.com/report"
    end

    @tag :tmp_dir
    test "accepts an address the translation ends with its own sentence punctuation", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "links.md")
      File.write!(source, "See https://example.com/report for details.")

      # Japanese closes the sentence with 。 and puts no space after the
      # address. The address is unchanged; only the prose around it moved.
      stub_stream(fn _account, _payload, _on_event ->
        translated("詳細は https://example.com/report。をご覧ください")
      end)

      item = work_item(%{source_abs: source, frontmatter_mode: :translate})

      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)
      assert result.text =~ "https://example.com/report"
    end

    @tag :tmp_dir
    test "restores a changed link destination without another model call", %{tmp_dir: dir} do
      source = Path.join(dir, "links.md")
      File.write!(source, "See [the report](https://example.com/report) for details.")

      {:ok, payloads} = Elixir.Agent.start_link(fn -> [] end)

      stub_stream(fn _account, payload, _on_event ->
        Elixir.Agent.update(payloads, &[payload | &1])

        assert payload["last_error"] in [nil, ""]
        translated("Consulta [el informe](https://example.com/es/report) para más detalles.")
      end)

      {:ok, events} = Elixir.Agent.start_link(fn -> [] end)
      on_event = fn event -> Elixir.Agent.update(events, &[event | &1]) end

      item = work_item(%{source_abs: source, frontmatter_mode: :translate})

      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, on_event)
      assert result.text =~ "https://example.com/report"
      refute result.text =~ "/es/report"

      calls = Elixir.Agent.get(payloads, &Enum.reverse/1)
      assert length(calls) == 1

      recorded = Elixir.Agent.get(events, &Enum.reverse/1)
      assert Enum.count(recorded, &match?({:attempt_start, _}, &1)) == 1
      assert Enum.count(recorded, &match?({:segment_retry, _, _}, &1)) == 0
    end
  end
end
