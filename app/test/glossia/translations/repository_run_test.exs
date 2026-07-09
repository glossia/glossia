defmodule Glossia.Translations.RepositoryRunTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.RepositoryRun

  test "parses git porcelain status into change entries" do
    output = """
     M docs/i18n/es/guide.md
    ?? docs/i18n/ja/guide.md
     D docs/i18n/de/old.md
    A  .glossia/docs/guide.md/es.lock
    """

    changes = RepositoryRun.parse_git_status(output)

    assert %{path: "docs/i18n/es/guide.md", status: "modified"} in changes
    assert %{path: "docs/i18n/ja/guide.md", status: "added"} in changes
    assert %{path: "docs/i18n/de/old.md", status: "deleted"} in changes
    assert %{path: ".glossia/docs/guide.md/es.lock", status: "added"} in changes
  end

  test "unquotes renamed and quoted paths, keeping the destination" do
    changes = RepositoryRun.parse_git_status(~s(R  old.md -> new.md\n M "with space.md"\n))
    assert %{path: "new.md", status: "modified"} in changes
    assert %{path: "with space.md", status: "modified"} in changes
  end
end
