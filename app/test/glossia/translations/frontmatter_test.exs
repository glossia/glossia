defmodule Glossia.Translations.FrontmatterTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Frontmatter

  describe "parse_content/1" do
    test "parses YAML frontmatter with a mapped sources spec" do
      {:ok, %{frontmatter: fm, body: body}} =
        Frontmatter.parse_content("""
        ---
        model: openai/gpt-5
        sources:
          "docs/*.md": "docs/i18n/{locale}/*.md"
        ---
        Hello
        """)

      assert fm.model == "openai/gpt-5"
      assert {:map, %{"docs/*.md" => "docs/i18n/{locale}/*.md"}} = fm.sources
      assert body == "Hello"
    end

    test "parses TOML frontmatter (+++ fence)" do
      {:ok, %{frontmatter: fm, body: body}} =
        Frontmatter.parse_content("""
        +++
        source_language = "en"
        model = "openai/gpt-5"
        +++
        Body text
        """)

      assert fm.source_language == "en"
      assert fm.model == "openai/gpt-5"
      assert body == "Body text"
    end

    test "content without a fence yields default frontmatter and trimmed body" do
      {:ok, %{frontmatter: fm, body: body}} = Frontmatter.parse_content("\nJust content\n")
      assert fm == %Frontmatter{}
      assert body == "Just content"
    end

    test "errors on an unterminated fence" do
      assert {:error, msg} = Frontmatter.parse_content("---\nmodel: x\nno closing marker")
      assert msg =~ "no closing ---"
    end
  end

  describe "split_markdown_frontmatter/1" do
    test "preserves the fence markers and splits the body" do
      split = Frontmatter.split_markdown_frontmatter("---\ntitle: Hello\n---\nBody")
      assert split.ok
      assert split.frontmatter == "---\ntitle: Hello\n---"
      assert split.body == "Body"
    end

    test "reports ok: false when there is no fence" do
      split = Frontmatter.split_markdown_frontmatter("no frontmatter here")
      refute split.ok
      assert split.body == "no frontmatter here"
    end
  end

  describe "translation_rules/1" do
    test "resolves generic translate rules" do
      {:ok, %{frontmatter: fm}} =
        Frontmatter.parse_content("""
        ---
        model: openai/gpt-5
        targets:
          es: Spanish
        translate:
          - source: docs/**/*.md
            output: docs/i18n/{locale}/{relpath}
        ---
        Hello
        """)

      assert {:ok, [rule]} = Frontmatter.translation_rules(fm)
      assert hd(rule.sources).pattern == "docs/**/*.md"
      assert rule.targets["es"] == "Spanish"
      assert rule.output == "docs/i18n/{locale}/{relpath}"
      assert rule.retries == 2
      assert rule.frontmatter == :preserve
    end

    test "derives a single rule from sources + targets" do
      {:ok, %{frontmatter: fm}} =
        Frontmatter.parse_content("""
        ---
        source_language: en
        sources:
          "docs/*.md": "docs/i18n/{locale}/*.md"
        targets:
          - es
          - ja
        ---
        """)

      assert {:ok, [rule]} = Frontmatter.translation_rules(fm)
      assert hd(rule.sources).pattern == "docs/*.md"
      assert hd(rule.sources).target_template == "docs/i18n/{locale}/*.md"
      assert rule.targets == %{"es" => "es", "ja" => "ja"}
    end

    test "errors when sources are configured without targets" do
      {:ok, %{frontmatter: fm}} =
        Frontmatter.parse_content("""
        ---
        sources:
          "docs/*.md": "docs/i18n/{locale}/*.md"
        ---
        """)

      assert {:error, msg} = Frontmatter.translation_rules(fm)
      assert msg =~ "targets are required"
    end

    test "no sources and no rules yields no work" do
      {:ok, %{frontmatter: fm}} = Frontmatter.parse_content("---\nsource_language: en\n---\nctx")
      assert {:ok, []} = Frontmatter.translation_rules(fm)
    end
  end

  describe "merge/2" do
    test "child non-nil fields override the parent; locale is not inherited" do
      {:ok, %{frontmatter: parent}} =
        Frontmatter.parse_content("---\nsource_language: en\nmodel: openai/gpt-5\n---\n")

      {:ok, %{frontmatter: child}} =
        Frontmatter.parse_content("---\nmodel: openai/gpt-5-mini\nlocale: es\n---\n")

      merged = Frontmatter.merge(parent, child)
      assert merged.model == "openai/gpt-5-mini"
      assert merged.source_language == "en"
      assert merged.locale == nil
    end
  end
end
