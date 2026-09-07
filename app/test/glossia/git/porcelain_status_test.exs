defmodule Glossia.Git.PorcelainStatusTest do
  use ExUnit.Case, async: true

  alias Glossia.Git.PorcelainStatus

  test "classifies modified, added (tracked and untracked), and deleted" do
    output = " M a.md\nA  b.md\n?? c.md\n D d.md\n"

    assert PorcelainStatus.parse(output) == [
             %{path: "a.md", status: "modified"},
             %{path: "b.md", status: "added"},
             %{path: "c.md", status: "added"},
             %{path: "d.md", status: "deleted"}
           ]
  end

  test "expands a rename into a deletion of the old path and an addition of the new" do
    assert PorcelainStatus.parse("R  old.md -> new.md\n") == [
             %{path: "old.md", status: "deleted"},
             %{path: "new.md", status: "added"}
           ]
  end

  test "a copy adds only the new path, leaving the original untouched" do
    assert PorcelainStatus.parse("C  base.md -> copy.md\n") == [
             %{path: "copy.md", status: "added"}
           ]
  end

  test "decodes git-quoted paths with special characters" do
    assert [%{path: "with space.md", status: "modified"}] =
             PorcelainStatus.parse(~s( M "with space.md"\n))
  end

  test "ignores blank and too-short lines" do
    assert PorcelainStatus.parse("\n  \nM\n") == []
  end
end
