defmodule Glossia.Translations.PlannerTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Planner

  @tag :tmp_dir
  test "target_path uses the path relative to the glob base", %{tmp_dir: root} do
    File.write!(Path.join(root, "GLOSSIA.md"), """
    ---
    source_language: en
    model: openai/gpt-5
    sources:
      "docs/*.md": "docs/i18n/{locale}/*.md"
    target_path: docs/i18n/{locale}
    targets:
      es: Spanish
    ---
    Global context
    """)

    File.mkdir_p!(Path.join(root, "docs"))
    File.write!(Path.join([root, "docs", "guide.md"]), "# Guide\n")

    assert {:ok, [item]} = Planner.build_plan(root, "es")
    assert item.output_path == "docs/i18n/es/guide.md"
    assert item.source_path == "docs/guide.md"
    assert item.locale == "es"
    assert item.language == "Spanish"
    assert item.source_language == "en"
    assert item.format == "markdown"
  end

  @tag :tmp_dir
  test "resolves context and model per matched source directory", %{tmp_dir: root} do
    File.write!(Path.join(root, "GLOSSIA.md"), """
    ---
    source_language: en
    model: gpt-5
    sources:
      "docs/**/*.md": "docs/i18n/{locale}/**"
    targets:
      - es
    ---
    Root context
    """)

    File.mkdir_p!(Path.join([root, "docs", "admin", "GLOSSIA"]))
    File.write!(Path.join([root, "docs", "GLOSSIA.md"]), "Docs context\n")
    File.write!(Path.join([root, "docs", "admin", "GLOSSIA.md"]), "Admin context\n")

    File.write!(
      Path.join([root, "docs", "admin", "GLOSSIA", "es.md"]),
      "---\nmodel: gpt-5-mini\n---\nAdmin Spanish\n"
    )

    File.write!(Path.join([root, "docs", "admin", "guide.md"]), "# Guide\n")

    assert {:ok, [item]} = Planner.build_plan(root, "es")
    assert item.context_body == "Root context\n\nDocs context\n\nAdmin context"
    assert item.locale_override_body == "Admin Spanish"
    assert item.output_path == "docs/i18n/es/admin/guide.md"
    assert item.model == "gpt-5-mini"
  end

  @tag :tmp_dir
  test "excludes matched files and skips GLOSSIA documents", %{tmp_dir: root} do
    File.write!(Path.join(root, "GLOSSIA.md"), """
    ---
    source_language: en
    model: gpt-5
    targets:
      es: Spanish
    translate:
      - source: docs/*.md
        output: docs/i18n/{locale}/{basename}.{ext}
        exclude:
          - docs/internal.md
    ---
    """)

    File.mkdir_p!(Path.join(root, "docs"))
    File.write!(Path.join([root, "docs", "guide.md"]), "# Guide\n")
    File.write!(Path.join([root, "docs", "internal.md"]), "# Internal\n")

    assert {:ok, items} = Planner.build_plan(root, "es")
    paths = Enum.map(items, & &1.source_path)
    assert paths == ["docs/guide.md"]
  end

  @tag :tmp_dir
  test "prefers a nested source declaration when roots plan the same output", %{tmp_dir: root} do
    File.write!(Path.join(root, "GLOSSIA.md"), """
    ---
    source_language: en
    model: openai/gpt-5
    sources:
      "app/docs/*.md": "app/i18n/{locale}/{relpath}"
    targets:
      es: Spanish
    prompt: Root prompt
    ---
    Root context
    """)

    File.mkdir_p!(Path.join([root, "app", "docs"]))

    File.write!(Path.join([root, "app", "GLOSSIA.md"]), """
    ---
    sources:
      "docs/*.md": "i18n/{locale}/{relpath}"
    prompt: Nested prompt
    ---
    App context
    """)

    File.write!(Path.join([root, "app", "docs", "guide.md"]), "# Guide\n")

    assert {:ok, [item]} = Planner.build_plan(root, "es")
    assert item.source_path == "app/docs/guide.md"
    assert item.output_path == "app/i18n/es/guide.md"
    assert item.prompt == "Nested prompt"
  end

  @tag :tmp_dir
  test "requires deterministic validation for a custom file extension", %{tmp_dir: root} do
    File.write!(Path.join(root, "GLOSSIA.md"), """
    ---
    source_language: en
    model: openai/gpt-5
    sources:
      "docs/*.custom": "docs/i18n/{locale}/{relpath}"
    targets:
      es: Spanish
    ---
    """)

    File.mkdir_p!(Path.join(root, "docs"))
    File.write!(Path.join([root, "docs", "guide.custom"]), "title(value)")

    assert {:error, message} = Planner.build_plan(root, "es")
    assert message =~ "no built-in format adapter for .custom files"
    assert message =~ "declare a validation command"

    File.write!(Path.join(root, "GLOSSIA.md"), """
    ---
    source_language: en
    model: openai/gpt-5
    sources:
      "docs/*.custom": "docs/i18n/{locale}/{relpath}"
    targets:
      es: Spanish
    validation:
      - sh
      - -c
      - test -f "$GLOSSIA_TARGET_PATH"
    ---
    """)

    assert {:ok, [item]} = Planner.build_plan(root, "es")
    assert item.format == "text"
    assert item.validation == ["sh", "-c", ~S|test -f "$GLOSSIA_TARGET_PATH"|]
  end
end
