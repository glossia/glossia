defmodule Glossia.DocsTest do
  use ExUnit.Case, async: true

  alias Glossia.Docs

  defp category(key, locale \\ "en"),
    do: Enum.find(Docs.navigation(locale), &(&1.key == key))

  defp section_pages(category, section_key) do
    group = Enum.find(category.sections, &(&1.key == section_key))
    Enum.map(group.pages, & &1.slug) ++ Enum.map(group.subcategories, & &1.key)
  end

  test "Markdown-only pages stay outside the documentation inventory in every locale" do
    for locale <- Glossia.I18n.locales() do
      pages = Docs.markdown_only_pages(locale)
      assert length(pages) == 5

      for page <- pages do
        assert page.markdown_only
        refute Enum.any?(Docs.all_pages(locale), &(&1.id == page.id))
        refute Enum.any?(Docs.category_items(page.category, locale), &(&1.id == page.id))
        refute Enum.any?(Docs.search_index(locale), &(&1.slug == page.slug))

        assert_raise Glossia.Docs.NotFoundError, fn ->
          Docs.get_page!(page.category, page.subcategory, page.slug, locale)
        end
      end
    end
  end

  describe "navigation/1" do
    test "groups pages under their frontmatter section, in section order" do
      explanation = category("explanation")

      assert Enum.map(explanation.sections, & &1.key) == ["translation", "platform", "analytics"]
      assert "glossary" in section_pages(explanation, "translation")
      assert section_pages(explanation, "platform") == ["account-models", "editions"]
      assert section_pages(explanation, "analytics") == ["localization-analytics"]
    end

    test "places reference subcategories in their section" do
      reference = category("reference")
      platform = section_pages(reference, "platform")

      assert "cli" in platform
      assert "apis" in platform
      assert "mcp" in platform
      assert "glossary" in section_pages(reference, "translation")
    end

    test "lists pages without a section first, under an untitled group" do
      tutorials = category("tutorials")

      assert [%{key: nil, title: nil} = group] = tutorials.sections
      assert Enum.map(group.pages, & &1.slug) == ["getting-started"]
    end

    test "gives section groups a title and an icon" do
      explanation = category("explanation")

      assert %{title: "Translation", icon: "language"} =
               Enum.find(explanation.sections, &(&1.key == "translation"))
    end

    test "groups ecosystem how-to guides in every locale" do
      for locale <- Glossia.I18n.locales() do
        how_to = category("how-to", locale)
        ecosystems = Enum.find(how_to.sections, &(&1.key == "ecosystems"))

        assert ecosystems.icon == "devices_code"
        assert section_pages(how_to, "ecosystems") == ["elixir-phoenix-gettext"]

        page = Docs.get_page!("how-to", nil, "elixir-phoenix-gettext", locale)
        assert page.section == "ecosystems"
        assert page.body =~ "sort_by_msgid"
        assert Enum.any?(Docs.search_index(locale), &(&1.slug == page.slug))
      end
    end

    test "translated pages keep the English page's section" do
      explanation = category("explanation", "es")
      assert "glossary" in section_pages(explanation, "translation")
    end
  end
end
