defmodule Glossia.Translations.ValidateTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Context
  alias Glossia.Translations.Locks
  alias Glossia.Translations.Validate

  describe "validate_syntax/3" do
    test "accepts valid and rejects invalid JSON/YAML" do
      assert :ok = Validate.validate_syntax("json", ~s({"a": 1}), "")
      assert {:error, _} = Validate.validate_syntax("json", "{not json", "")
      assert :ok = Validate.validate_syntax("yaml", "a: 1\n", "")
    end

    test "validates fenced and NimblePublisher markdown frontmatter" do
      assert :ok = Validate.validate_syntax("markdown", "# Just prose", "")
      assert :ok = Validate.validate_syntax("markdown", "---\ntitle: Hi\n---\nBody", "")
      assert {:error, msg} = Validate.validate_syntax("markdown", "---\ntitle: Hi\nno close", "")
      assert msg =~ "frontmatter invalid"

      assert :ok =
               Validate.validate_syntax(
                 "markdown",
                 "%{\n  title: \"Hello\",\n  date: ~D[2026-02-03]\n}\n---\nBody",
                 ""
               )

      assert {:error, message} =
               Validate.validate_syntax(
                 "markdown",
                 "%{\n  title: \"Unclosed\n}\n---\nBody",
                 ""
               )

      assert message =~ "frontmatter invalid"
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

    test "rejects added or duplicated protected tokens" do
      assert {:error, message} =
               Validate.validate_preserve(
                 "Visit https://example.com twice: https://example.com",
                 "Visit https://example.com",
                 ["urls"]
               )

      assert message =~ "unexpected preserved tokens"

      assert {:error, message} =
               Validate.validate_preserve(
                 "Hello {name}",
                 "Hello {name} and {name}",
                 ["placeholders"]
               )

      assert message =~ "preserved tokens missing"
    end
  end

  describe "declared validation command" do
    @tag :tmp_dir
    test "reads the candidate from the target path and restores the previous file", %{
      tmp_dir: root
    } do
      source = Path.join(root, "source.md")
      target = Path.join(root, "ja/target.md")
      doc = Path.join(root, "GLOSSIA.md")
      File.write!(source, "source")
      File.mkdir_p!(Path.dirname(target))
      File.write!(target, "previous")
      File.write!(doc, "configuration")

      options = validation_options(source, target, doc)

      assert :ok =
               Validate.validate_output(root, "text", "candidate", "source", options)

      assert File.read!(target) == "previous"
    end

    @tag :tmp_dir
    test "removes a staged candidate when the target did not exist", %{tmp_dir: root} do
      source = Path.join(root, "source.md")
      target = Path.join(root, "ja/target.md")
      doc = Path.join(root, "GLOSSIA.md")
      File.write!(source, "source")
      File.write!(doc, "configuration")

      options = validation_options(source, target, doc)

      assert :ok =
               Validate.validate_output(root, "text", "candidate", "source", options)

      refute File.exists?(target)
    end

    @tag :tmp_dir
    test "restores the previous file when validation fails", %{tmp_dir: root} do
      source = Path.join(root, "source.md")
      target = Path.join(root, "ja/target.md")
      doc = Path.join(root, "GLOSSIA.md")
      File.write!(source, "source")
      File.mkdir_p!(Path.dirname(target))
      File.write!(target, "previous")
      File.write!(doc, "configuration")

      options = validation_options(source, target, doc)

      assert {:error, message} =
               Validate.validate_output(root, "text", "invalid candidate", "source", options)

      assert message =~ "validation failed"
      assert File.read!(target) == "previous"
    end
  end

  describe "PO validation" do
    test "accepts a valid PO file" do
      po =
        ~s(msgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n"Plural-Forms: nplurals=2; plural=n != 1;\\n"\n\nmsgid "Hello"\nmsgstr "Hola"\n)

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

    test "effective server context and custom prompts participate in the dependency tree" do
      base = hash_state_input()
      original = Locks.build_hash_state(base)

      changed_prompt =
        base
        |> Map.put(:custom_prompt, "Use a formal register.")
        |> Locks.build_hash_state()

      changed_terminology =
        base
        |> Map.put(:server_context, server_context("Cuenta"))
        |> Locks.build_hash_state()

      changed_validation =
        base
        |> Map.put(:validation, ["mix", "test"])
        |> Locks.build_hash_state()

      assert original.hash != changed_prompt.hash
      assert original.hash != changed_terminology.hash
      assert original.hash != changed_validation.hash

      [_, config_node, _] = get_in(original.tree, ["root", "children"])
      assert config_node["metadata"]["segmentation_version"] == 1
      assert config_node["metadata"]["preservation_version"] == 5
    end

    test "unrelated server version changes do not invalidate identical effective context" do
      first = server_context("Cuenta", 1, 2)
      second = server_context("Cuenta", 7, 9)

      first_hash =
        hash_state_input()
        |> Map.put(:server_context, first)
        |> Locks.build_hash_state()

      second_hash =
        hash_state_input()
        |> Map.put(:server_context, second)
        |> Locks.build_hash_state()

      assert first_hash.hash == second_hash.hash
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

  defp hash_state_input do
    %{
      format: "markdown",
      source_path: "docs/guide.md",
      source_content: "Create an Account.",
      provider: "openai",
      model: "openai/gpt-5",
      source_language: "en",
      language: "Spanish",
      locale: "es",
      frontmatter_mode: :preserve,
      preserve: [],
      custom_prompt: nil,
      context_body: "Project context",
      locale_override_body: "",
      server_context: Context.empty_bundle("es")
    }
  end

  defp server_context(translation, voice_version \\ 1, glossary_version \\ 1) do
    %{
      Context.empty_bundle("es")
      | snapshot: %{
          Context.empty_snapshot()
          | voice_version: voice_version,
            glossary_version: glossary_version
        },
        terminology: [
          %{
            id: "account",
            term: "Account",
            translation: translation,
            definition: nil,
            case_sensitive: false
          }
        ]
    }
  end

  defp validation_options(source, target, doc) do
    %{
      validation: [
        "sh",
        "-c",
        ~S|test "$(cat "$GLOSSIA_TARGET_PATH")" = "candidate"|
      ],
      validation_doc_abs: doc,
      source_abs: source,
      target_abs: target,
      locale: "ja"
    }
  end
end
