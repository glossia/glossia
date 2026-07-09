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

  test "expands a rename into a deletion of the old path and an addition of the new" do
    changes = RepositoryRun.parse_git_status(~s(R  old.md -> new.md\n M "with space.md"\n))
    assert %{path: "old.md", status: "deleted"} in changes
    assert %{path: "new.md", status: "added"} in changes
    assert %{path: "with space.md", status: "modified"} in changes
  end

  test "a copy adds only the new path" do
    changes = RepositoryRun.parse_git_status("C  base.md -> copy.md\n")
    assert %{path: "copy.md", status: "added"} in changes
    refute Enum.any?(changes, &(&1.path == "base.md"))
  end
end
