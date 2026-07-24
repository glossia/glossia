defmodule Glossia.Translations.EngineTest do
  use ExUnit.Case, async: true
  use Mimic

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
        translated("translated segment #{payload["segment_index"]}")
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

      assert result.text ==
               "%{\n  title: \"Hello\",\n  date: ~D[2026-02-03]\n}\n---\ntranslated segment 1\n\ntranslated segment 2"
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
    test "translates frontmatter as an isolated segment when requested", %{tmp_dir: dir} do
      source = Path.join(dir, "guide.md")
      File.write!(source, "%{\n  title: \"Hello\"\n}\n---\n\nBody")

      stub_stream(fn _account, payload, _on_event ->
        case payload["segment_kind"] do
          "frontmatter" ->
            assert payload["segment_index"] == 1
            translated("%{\n  title: \"Hola\"\n}\n---")

          "content" ->
            assert payload["segment_index"] == 2
            translated("Cuerpo")
        end
      end)

      item = work_item(%{source_abs: source, frontmatter_mode: :translate})
      assert {:ok, result} = Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end)
      assert result.text == "%{\n  title: \"Hola\"\n}\n---\nCuerpo"
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
    test "masks preserved tokens before translation and reconstructs the exact values", %{
      tmp_dir: dir
    } do
      source = Path.join(dir, "guide.md")

      File.write!(
        source,
        "Visit [Glossia](https://glossia.ai/{locale}) and run `mix test`."
      )

      stub_stream(fn _account, payload, _on_event ->
        refute payload["source_content"] =~ "https://glossia.ai/{locale}"
        refute payload["source_content"] =~ "`mix test`"
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
  end
end
