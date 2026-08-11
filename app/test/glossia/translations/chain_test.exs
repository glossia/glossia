defmodule Glossia.Translations.ChainTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Chain

  defp git!(root, args) do
    {_output, 0} =
      MuonTrap.cmd("git", ["-C", root | args], stderr_to_stdout: true, into: "")

    :ok
  end

  @tag :tmp_dir
  test "resolves an inherited model identifier and merges bodies", %{tmp_dir: root} do
    File.write!(Path.join(root, "GLOSSIA.md"), """
    ---
    source_language: en
    model: openai/gpt-5
    frontmatter: preserve
    ---
    Global context
    """)

    File.mkdir_p!(Path.join(root, "docs"))

    File.write!(Path.join([root, "docs", "GLOSSIA.md"]), """
    ---
    model: openai/gpt-5-mini
    sources:
      "*.md": "i18n/{locale}/*.md"
    ---
    Docs context
    """)

    assert {:ok, resolved} = Chain.resolve_chain(Path.join(root, "docs"), root)
    assert resolved.merged_frontmatter.model == "openai/gpt-5-mini"
    assert resolved.merged_frontmatter.frontmatter == :preserve
    assert resolved.merged_body == "Global context\n\nDocs context"
  end

  @tag :tmp_dir
  test "finds only directories whose GLOSSIA.md declares sources", %{tmp_dir: root} do
    File.write!(
      Path.join(root, "GLOSSIA.md"),
      "---\nsource_language: en\nmodel: openai/gpt-5\n---\nroot"
    )

    File.mkdir_p!(Path.join(root, "server"))

    File.write!(
      Path.join([root, "server", "GLOSSIA.md"]),
      "---\nsources:\n  \"priv/gettext/*.pot\": \"priv/gettext/{locale}/LC_MESSAGES\"\n---\nserver"
    )

    assert {:ok, [dir]} = Chain.find_translation_roots(root)
    assert Path.basename(dir) == "server"
  end

  @tag :tmp_dir
  test "ignores translation roots excluded by Git", %{tmp_dir: root} do
    git!(root, ["init", "-q"])

    File.write!(Path.join(root, ".gitignore"), "/tmp\n")

    File.write!(Path.join(root, "GLOSSIA.md"), """
    ---
    source_language: en
    sources:
      "docs/*.md": "docs/i18n/{locale}/*.md"
    targets:
      es: Spanish
    ---
    """)

    File.mkdir_p!(Path.join(root, "docs"))
    File.write!(Path.join([root, "docs", "guide.md"]), "# Guide\n")

    File.mkdir_p!(Path.join([root, "tmp", "nested", "docs"]))

    File.write!(Path.join([root, "tmp", "nested", "GLOSSIA.md"]), """
    ---
    source_language: en
    sources:
      "docs/*.custom": "docs/i18n/{locale}/*.custom"
    targets:
      es: Spanish
    ---
    """)

    File.write!(Path.join([root, "tmp", "nested", "docs", "guide.custom"]), "guide")

    assert {:ok, [item]} = Glossia.Translations.Planner.build_plan(root, "es")
    assert item.source_path == "docs/guide.md"
  end

  @tag :tmp_dir
  test "resolves the effective validation from the deepest scope", %{tmp_dir: root} do
    File.write!(
      Path.join(root, "GLOSSIA.md"),
      "---\nsource_language: en\nvalidation:\n  - ./root-check.sh\n---\nroot"
    )

    File.mkdir_p!(Path.join(root, "docs"))

    File.write!(
      Path.join([root, "docs", "GLOSSIA.md"]),
      "---\nvalidation:\n  - ./docs-check.sh\n---\ndocs"
    )

    assert {:ok, resolved} = Chain.resolve_chain(Path.join(root, "docs"), root)
    assert resolved.validation.relative_path == "docs/GLOSSIA.md"
    assert resolved.validation.argv == ["./docs-check.sh"]
  end

  @tag :tmp_dir
  test "loads a locale overlay and captures its model override", %{tmp_dir: root} do
    File.write!(
      Path.join(root, "GLOSSIA.md"),
      "---\nsource_language: en\nmodel: openai/gpt-5\n---\nglobal"
    )

    File.mkdir_p!(Path.join(root, "GLOSSIA"))

    File.write!(
      Path.join([root, "GLOSSIA", "es.md"]),
      "---\nlocale: es\nmodel: openai/gpt-5-mini\n---\nSpanish overlay"
    )

    assert {:ok, override} = Chain.load_locale_override(root, root, "es")
    assert override.model == "openai/gpt-5-mini"
    assert override.merged_body == "Spanish overlay"
  end

  @tag :tmp_dir
  test "rejects a locale overlay that declares a mismatched locale", %{tmp_dir: root} do
    File.write!(
      Path.join(root, "GLOSSIA.md"),
      "---\nsource_language: en\nmodel: openai/gpt-5\n---\nglobal"
    )

    File.mkdir_p!(Path.join(root, "GLOSSIA"))
    File.write!(Path.join([root, "GLOSSIA", "es.md"]), "---\nlocale: ja\n---\noops")

    assert {:error, msg} = Chain.load_locale_override(root, root, "es")
    assert msg =~ "expected es"
  end
end
