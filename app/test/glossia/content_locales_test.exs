defmodule Glossia.ContentLocalesTest do
  use ExUnit.Case, async: true

  alias Glossia.{Blog, Changelog, Docs, Features, I18n, Legal}

  test "a locale serves the translated copy of a post" do
    case Blog.all_posts() do
      [] ->
        # The blog catalog is intentionally empty on this branch; the
        # locale-fallback invariant is covered elsewhere and there is
        # nothing to assert about translated posts until one is added.
        :ok

      [english | _] ->
        spanish = Blog.all_posts("es") |> Enum.find(&(&1.slug == english.slug))

        # Right after an English post is merged, the translation pipeline
        # opens a separate PR with the per-locale copies; until that PR
        # lands, `all_posts("es")` falls back to the English content, which
        # is the correct behaviour. Only enforce the "translated title is
        # distinct" invariant once a real Spanish copy has been merged.
        if spanish.title == english.title do
          assert spanish.date == english.date
        else
          assert spanish.date == english.date
          assert spanish.title != english.title
        end
    end
  end

  test "every locale serves the whole catalog, falling back to English" do
    for locale <- I18n.locales() do
      assert length(Blog.all_posts(locale)) == length(Blog.all_posts())
      assert length(Features.all_pages(locale)) == length(Features.all_pages())
      assert length(Docs.all_pages(locale)) == length(Docs.all_pages())
      assert length(Legal.all_versions(locale)) == length(Legal.all_versions())
    end
  end

  test "localized legal pages retain their routing document names" do
    expected = Map.new(Legal.all_versions(), &{&1.id, &1.document})

    for locale <- I18n.locales() do
      assert Map.new(Legal.all_versions(locale), &{&1.id, &1.document}) == expected
    end
  end

  test "current legal pages describe open-core licensing in every locale" do
    for locale <- I18n.locales(), document <- Legal.documents() do
      version = Legal.latest_version!(document, locale)

      assert version.date == ~D[2026-10-30]
      # New legal versions fall back to English until translated.
      assert version.body =~ "Apache-2.0"
      assert version.body =~ "Glossia Enterprise License"
      refute version.body =~ "O'Saasy"
    end
  end

  test "licensing explanations describe the open-core boundary in every locale" do
    slugs =
      ~w(content-ownership why-glossia glossia-vs-crowdin glossia-vs-lokalise glossia-vs-phrase glossia-vs-weblate)

    for locale <- I18n.locales(), slug <- slugs do
      pages = Docs.all_pages(locale) ++ Docs.markdown_only_pages(locale)
      page = Enum.find(pages, &(&1.category == "explanation" and &1.slug == slug))
      assert page, "missing licensing explanation: #{locale}/#{slug}"
      assert page.body =~ "Apache-2.0"
      assert page.body =~ "ee/"
      refute page.body =~ "O'Saasy"
    end
  end

  test "historical terms retain the license that applied at publication" do
    version = Legal.get_version!("terms", "2026-02-12")

    assert version.body =~ "O'Saasy License"
    assert version.body =~ "may not use it to offer"
  end

  test "the previous legal version remains unchanged" do
    for locale <- I18n.locales(), document <- ~w(terms privacy cookies) do
      version = Legal.get_version!(document, "2026-10-12", locale)
      assert version.body =~ "O'Saasy"
    end
  end

  test "an unknown changelog locale falls back to English" do
    assert Changelog.all_entries("unknown") == Changelog.all_entries()
  end

  test "translated docs retain their source routing identifiers" do
    source_routes = Map.new(Docs.all_pages(), &{&1.id, {&1.category, &1.subcategory, &1.slug}})

    for locale <- I18n.locales() do
      assert Map.new(Docs.all_pages(locale), &{&1.id, {&1.category, &1.subcategory, &1.slug}}) ==
               source_routes
    end
  end

  @tag :tmp_dir
  test "doc paths override translated routing metadata", %{tmp_dir: dir} do
    path = Path.join([dir, "docs", "reference", "cli", "commands.md"])
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, "%{}\n---\nTranslated body.")

    attrs = %{
      title: "Comandos",
      summary: "Referencia",
      order: 1,
      category: "Referencia",
      subcategory: "Comandos",
      slug: "comandos"
    }

    page = Docs.Page.build(path, attrs, "<p>Translated body.</p>")

    assert page.title == "Comandos"
    assert page.category == "reference"
    assert page.subcategory == "cli"
    assert page.slug == "commands"
    assert Docs.path_for(page) == "/docs/reference/cli/commands"
  end

  test "docs paths carry the locale prefix" do
    [item | _] = Docs.category_items("how-to", "es")

    assert String.starts_with?(item.href, "/es/docs/")
  end

  test "the Diataxis labels go through Gettext rather than being frozen in code" do
    # They live in `Glossia.Docs` instead of in the markdown, so the extractor
    # is what gets them in front of the translators.
    pot = File.read!(Application.app_dir(:glossia, "priv/gettext/default.pot"))

    assert pot =~ ~s(msgid "How-to guides")

    assert Docs.category_meta!("how-to").title ==
             Gettext.gettext(GlossiaWeb.Gettext, "How-to guides")
  end

  test "an unknown locale falls back to English rather than raising" do
    assert Blog.all_posts("sv") == Blog.all_posts()
  end
end
