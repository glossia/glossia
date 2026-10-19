defmodule Glossia.Translations.RepositoryRunTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Glossia.Translations.RepositoryRun

  defp git!(root, args) do
    {_output, 0} = MuonTrap.cmd("git", ["-C", root | args], into: "", timeout: 10_000)
  end

  defp init_repo(root) do
    git!(root, ["init", "-q"])
    git!(root, ["config", "user.email", "test@example.com"])
    git!(root, ["config", "user.name", "Tester"])
    git!(root, ["config", "commit.gpgsign", "false"])
    git!(root, ["config", "core.hooksPath", "/dev/null"])
  end

  @tag :tmp_dir
  test "scopes collection to literal owned paths before reading other artifacts", %{tmp_dir: root} do
    init_repo(root)
    File.mkdir_p!(Path.join(root, "docs"))
    File.write!(Path.join(root, "docs/[draft].md"), "translated")
    File.write!(Path.join(root, "docs/d.md"), "other worker")
    File.ln_s!("missing-target", Path.join(root, "unrelated.md"))

    assert {:ok, [%{path: "docs/[draft].md", status: "added", content: "translated"}]} =
             RepositoryRun.collect_changes(root, ["docs/[draft].md"])

    git!(root, ["add", "docs"])
    git!(root, ["commit", "-q", "-m", "baseline"])
    assert {:ok, []} = RepositoryRun.collect_changes(root, ["docs/[draft].md"])

    File.write!(Path.join(root, "docs/[draft].md"), "updated")

    assert {:ok, [%{path: "docs/[draft].md", status: "modified", content: "updated"}]} =
             RepositoryRun.collect_changes(root, ["docs/[draft].md"])

    File.rm!(Path.join(root, "docs/[draft].md"))

    assert {:ok, [%{path: "docs/[draft].md", status: "deleted", content: nil}]} =
             RepositoryRun.collect_changes(root, ["docs/[draft].md"])
  end

  @tag :tmp_dir
  test "preserves literal filenames with Unicode, arrows, quotes and control characters", %{
    tmp_dir: root
  } do
    init_repo(root)
    File.mkdir_p!(Path.join(root, "docs"))

    for path <- [
          "docs/Guía \"intro\".md",
          "docs/a -> b.md",
          "docs/line\nbreak\t.md ",
          "docs/control\x01.md"
        ] do
      File.write!(Path.join(root, path), "Hola")

      assert {:ok, [%{path: ^path, status: "added", content: "Hola"}]} =
               RepositoryRun.collect_changes(root, [path])
    end
  end

  @tag :tmp_dir
  test "captures every path and content in large Git manifests", %{tmp_dir: root} do
    init_repo(root)
    File.mkdir_p!(Path.join(root, "translations/es"))

    expected =
      Map.new(1..600, fn n ->
        path = "translations/es/#{n}-#{String.duplicate("x", 100)}.md"
        content = "Translation #{n}\n"
        File.write!(Path.join(root, path), content)
        {path, content}
      end)

    for _ <- 1..5 do
      assert {:ok, changes} = RepositoryRun.collect_changes(root)
      assert length(changes) == map_size(expected)
      assert Map.new(changes, &{&1.path, &1.content}) == expected
      assert Enum.all?(changes, &(&1.status == "added"))
    end
  end

  test "rejects a truncated status record instead of reading a partial pathname" do
    stub(MuonTrap, :cmd, fn "git", _args, _opts -> {"?? private/incomplete", 0} end)

    assert {:error, :translation_change_manifest_incomplete} =
             RepositoryRun.collect_changes("/repo")
  end

  @tag :tmp_dir
  test "returns structured errors when a manifest artifact disappears", %{tmp_dir: root} do
    stub(MuonTrap, :cmd, fn "git", _args, _opts -> {"?? missing.md\0", 0} end)

    assert {:error, {:translation_artifact_unreadable, :enoent}} =
             RepositoryRun.collect_changes(root)
  end

  test "does not retain command output when Git fails" do
    stub(MuonTrap, :cmd, fn "git", _args, _opts -> {"TOKEN=secret", 128} end)
    assert {:error, {:git_status_failed, 128}} = RepositoryRun.collect_changes("/repo")
  end

  test "parses NUL-framed renames and copies without interpreting filename contents" do
    assert {:ok, changes} =
             Glossia.Git.PorcelainStatus.parse_z(
               "?? a -> b.md\0R  new\nname.md\0old.md\0C  copy.md\0base.md\0"
             )

    assert changes == [
             %{path: "a -> b.md", status: "added"},
             %{path: "old.md", status: "deleted"},
             %{path: "new\nname.md", status: "added"},
             %{path: "copy.md", status: "added"}
           ]

    for malformed <- ["?? missing", "?? \0", "R  new.md\0", "R  new.md\0old.md"] do
      assert {:error, :incomplete_status} = Glossia.Git.PorcelainStatus.parse_z(malformed)
    end
  end

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
