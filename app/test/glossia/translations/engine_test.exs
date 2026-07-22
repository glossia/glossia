defmodule Glossia.Translations.EngineTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Glossia.Accounts.Account
  alias Glossia.Translations
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
        locale_override_body: ""
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

      assert {:error, {:validation_failed, "nope"}} =
               Engine.apply_item(item, %Account{id: 1}, fn _ -> :ok end, fn _, _ ->
                 {:error, "nope"}
               end)
    end
  end
end
