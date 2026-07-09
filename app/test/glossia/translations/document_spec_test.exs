defmodule Glossia.Translations.DocumentSpecTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.DocumentSpec
  alias Glossia.Translations.Frontmatter

  describe "validate_document/2" do
    test "rejects a root document without source_language" do
      assert {:error, "GLOSSIA.md must declare source_language"} =
               DocumentSpec.validate_document("GLOSSIA.md", %Frontmatter{})
    end

    test "rejects a top-level sources list for spec documents" do
      assert {:error, msg} =
               DocumentSpec.validate_document("docs/GLOSSIA.md", %Frontmatter{
                 sources: {:list, ["docs/*.md"]}
               })

      assert msg =~ "sources must be a mapping"
    end

    test "rejects duplicate targets" do
      assert {:error, "targets must not contain duplicate locales"} =
               DocumentSpec.validate_document("docs/GLOSSIA.md", %Frontmatter{
                 targets: {:list, ["es", "es"]}
               })
    end

    test "accepts mapped sources and list targets" do
      fm = %Frontmatter{
        sources: {:map, %{"docs/*.md" => "docs/i18n/{locale}/*.md"}},
        targets: {:list, ["es", "ja"]}
      }

      assert :ok = DocumentSpec.validate_document("docs/GLOSSIA.md", fm)
    end

    test "accepts a locale overlay when the locale matches the filename" do
      fm = %Frontmatter{locale: "es", model: "openai/gpt-5"}
      assert :ok = DocumentSpec.validate_document("docs/GLOSSIA/es.md", fm)
    end

    test "rejects a locale overlay whose declared locale mismatches the filename" do
      assert {:error, msg} =
               DocumentSpec.validate_document("docs/GLOSSIA/es.md", %Frontmatter{locale: "ja"})

      assert msg =~ "expected es"
    end

    test "rejects an empty model identifier" do
      assert {:error, "model must be a non-empty model identifier"} =
               DocumentSpec.validate_document("docs/GLOSSIA.md", %Frontmatter{model: "   "})
    end
  end

  describe "classify/1" do
    test "classifies document kinds by their repo-relative path" do
      assert {:ok, :global} = DocumentSpec.classify("GLOSSIA.md")
      assert {:ok, :scoped} = DocumentSpec.classify("docs/GLOSSIA.md")
      assert {:ok, {:locale_overlay, "es"}} = DocumentSpec.classify("docs/GLOSSIA/es.md")
      assert {:ok, {:locale_overlay, "pt-BR"}} = DocumentSpec.classify("GLOSSIA/pt-BR.md")
      assert {:error, _} = DocumentSpec.classify("random.md")
    end
  end
end
