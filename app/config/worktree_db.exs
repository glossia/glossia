defmodule Glossia.Config.WorktreeDB do
  @moduledoc false

  @max_slug_length 20

  def dev_database(base \\ "glossia_dev") do
    "#{base}_#{suffix()}"
  end

  def test_database(base \\ "glossia_test") do
    partition = System.get_env("MIX_TEST_PARTITION", "")
    "#{base}_#{suffix()}#{partition}"
  end

  defp suffix do
    case System.get_env("GLOSSIA_DB_SUFFIX") do
      nil -> default_suffix()
      "" -> default_suffix()
      value -> normalize_slug(value)
    end
  end

  defp default_suffix do
    cwd = File.cwd!()
    hash = short_hash(cwd)

    slug =
      cwd
      |> Path.basename()
      |> normalize_slug()
      |> String.slice(0, @max_slug_length)

    if slug == "", do: hash, else: "#{slug}_#{hash}"
  end

  defp short_hash(value) do
    value
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> binary_part(0, 8)
  end

  defp normalize_slug(value) do
    value
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]/u, "_")
    |> String.trim("_")
    |> case do
      "" -> "worktree"
      slug -> slug
    end
  end
end
