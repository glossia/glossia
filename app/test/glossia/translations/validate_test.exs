defmodule Glossia.Translations.ValidateTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Locks
  alias Glossia.Translations.Validate

  describe "validate_syntax/3" do
    test "accepts valid and rejects invalid JSON/YAML" do
      assert :ok = Validate.validate_syntax("json", ~s({"a": 1}), "")
      assert {:error, _} = Validate.validate_syntax("json", "{not json", "")
      assert :ok = Validate.validate_syntax("yaml", "a: 1\n", "")
    end

    test "validates markdown frontmatter only when a fence is present" do
      assert :ok = Validate.validate_syntax("markdown", "# Just prose", "")
      assert :ok = Validate.validate_syntax("markdown", "---\ntitle: Hi\n---\nBody", "")
      assert {:error, msg} = Validate.validate_syntax("markdown", "---\ntitle: Hi\nno close", "")
      assert msg =~ "frontmatter invalid"
    end

    test "text is always valid" do
      assert :ok = Validate.validate_syntax("text", "anything", "")
    end
  end

  describe "preserve" do
    test "resolve_preserve/1 handles defaults and none" do
      assert Validate.resolve_preserve([]) == ~w(code_blocks inline_code urls placeholders)
      assert Validate.resolve_preserve(["none"]) == []
      assert Validate.resolve_preserve(["URLs", " Placeholders "]) == ["urls", "placeholders"]
    end

    test "flags placeholders/urls/inline code dropped in translation" do
      source = "Visit `run` at https://x.io/y with {count} items."
      kinds = ~w(inline_code urls placeholders)

      assert :ok = Validate.validate_preserve(source, source, kinds)

      assert {:error, msg} =
               Validate.validate_preserve("Visita con elementos.", source, kinds)

      assert msg =~ "preserved tokens missing"
      assert msg =~ "{count}"
    end

    test "preserves fenced code blocks as whole tokens" do
      source = "Intro\n```elixir\nIO.puts(1)\n```\nEnd {x}"
      assert :ok = Validate.validate_preserve(source, source, ["code_blocks", "placeholders"])
      assert {:error, _} = Validate.validate_preserve("Sin bloque", source, ["code_blocks"])
    end
  end

  describe "PO validation" do
    test "accepts a valid PO file" do
      po = ~s(msgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n"Plural-Forms: nplurals=2; plural=n != 1;\\n"\n\nmsgid "Hello"\nmsgstr "Hola"\n)
      assert :ok = Validate.validate_syntax("po", po, po)
    end

    test "rejects a PO file without a header entry" do
      po = ~s(msgid "Hello"\nmsgstr "Hola"\n)
      assert {:error, msg} = Validate.validate_syntax("po", po, "")
      assert msg =~ "missing header"
    end
  end

  describe "Locks" do
    test "PO source hash ignores line-number churn" do
      left = "#: lib/app.ex:10\nmsgid \"Hello\"\nmsgstr \"\""
      right = "#: lib/app.ex:99\nmsgid \"Hello\"\nmsgstr \"\""
      assert Locks.source_hash("po", left) == Locks.source_hash("po", right)
    end

    test "model and context participate in the input hash" do
      base = ["markdown", "Body", "openai", "gpt-5", "ctx", ""]
      h1 = apply(Locks, :build_hash, base)
      h2 = apply(Locks, :build_hash, ["markdown", "Body", "openai", "gpt-5-mini", "ctx", ""])
      h3 = apply(Locks, :build_hash, ["markdown", "Body", "openai", "gpt-5", "other", ""])
      assert h1 != h2
      assert h1 != h3
    end

    @tag :tmp_dir
    test "round-trips a lockfile and detects staleness", %{tmp_dir: root} do
      lock = Locks.build_lock("openai", "gpt-5", "docs/g.md", "docs/es/g.md", "salida", "hash-1")
      :ok = Locks.write_lock(root, "docs/g.md", "es", lock)

      read = Locks.read_lock(root, "docs/g.md", "es")
      assert read["output_path"] == "docs/es/g.md"

      refute Locks.stale?(read, "hash-1", "docs/es/g.md", Locks.output_hash("salida"))
      assert Locks.stale?(read, "hash-2", "docs/es/g.md", Locks.output_hash("salida"))
      assert Locks.stale?(nil, "hash-1", "docs/es/g.md", "x")
    end
  end
end
