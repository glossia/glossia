defmodule Glossia.Translations.GlobTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Glob

  test "computes the glob base from wildcards" do
    assert Glob.glob_base("docs/*.md") == "docs"
    assert Glob.glob_base("docs/**/*.md") == "docs"
    assert Glob.glob_base("*.md") == "."
    assert Glob.glob_base("priv/gettext/errors.pot") == "priv/gettext"
  end

  test "matches globs with literal separators (`*` does not cross `/`, `**` does)" do
    files = ["docs/guide.md", "docs/nested/guide.md", "notes.md"]

    assert Glob.glob_files("docs/*.md", files) == ["docs/guide.md"]

    assert Glob.glob_files("docs/**/*.md", files) == [
             "docs/guide.md",
             "docs/nested/guide.md"
           ]
  end

  test "leading ** matches zero or more directories" do
    files = ["guide.md", "docs/guide.md", "docs/nested/guide.md"]
    assert Glob.glob_files("**/*.md", files) == files
  end

  test "? matches a single non-separator character" do
    files = ["a.md", "ab.md", "a/b.md"]
    assert Glob.glob_files("?.md", files) == ["a.md"]
  end
end
