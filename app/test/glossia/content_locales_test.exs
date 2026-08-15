defmodule Glossia.ContentLocalesTest do
  use ExUnit.Case, async: true

  alias Glossia.{Blog, Changelog, Docs, Features, I18n, Legal}

  test "a locale serves the translated copy of a post" do
    english = Blog.all_posts() |> List.first()
    spanish = Blog.all_posts("es") |> Enum.find(&(&1.slug == english.slug))

    assert spanish.title != english.title
    assert spanish.date == english.date
  end

  test "every locale serves the whole catalog, falling back to English" do
    for locale <- I18n.locales() do
      assert length(Blog.all_posts(locale)) == length(Blog.all_posts())
      assert length(Features.all_pages(locale)) == length(Features.all_pages())
      assert length(Docs.all_pages(locale)) == length(Docs.all_pages())
      assert length(Legal.all_versions(locale)) == length(Legal.all_versions())
    end
  end

  test "a section with no translations yet keeps serving English" do
    assert Changelog.all_entries("ja") == Changelog.all_entries()
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
