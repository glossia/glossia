defmodule Glossia.Translations.Glob do
  @moduledoc """
  Glob matching over a repository's relative file list.

  Ported from the CLI (`cli/src/glob.rs`), which uses `globset` with
  `literal_separator(true)`: `*` and `?` do not cross `/`, while `**` spans
  directories. `walk_files/1` lists files relative to a root (skipping `.git`);
  `glob_files/2` filters that list by a pattern; `glob_base/1` returns the fixed
  directory prefix of a pattern.
  """

  @globstar "\x00"

  @doc "Lists files under `root` (recursively, skipping `.git`) as `/`-separated relative paths."
  def walk_files(root) do
    root = Path.expand(root)
    do_walk(root, root)
  end

  defp do_walk(dir, root) do
    case File.ls(dir) do
      {:ok, entries} ->
        Enum.flat_map(entries, fn entry -> walk_entry(entry, dir, root) end)

      {:error, _reason} ->
        []
    end
  end

  defp walk_entry(".git", _dir, _root), do: []

  defp walk_entry(entry, dir, root) do
    full = Path.join(dir, entry)

    cond do
      File.dir?(full) -> do_walk(full, root)
      File.regular?(full) -> [normalize_slashes(Path.relative_to(full, root))]
      true -> []
    end
  end

  @doc "Returns the files matching `pattern`."
  def glob_files(pattern, files) do
    regex = compile_matcher(pattern)
    Enum.filter(files, &Regex.match?(regex, &1))
  end

  @doc "The fixed directory prefix of a pattern (before the first wildcard), or `\".\"`."
  def glob_base(pattern) do
    normalized = normalize_slashes(pattern)

    case find_wildcard_index(normalized) do
      nil ->
        parent_or_dot(normalized)

      index ->
        prefix = String.slice(normalized, 0, index)
        trimmed = String.trim_trailing(prefix, "/")

        cond do
          trimmed == "" -> "."
          String.ends_with?(prefix, "/") -> trimmed
          true -> parent_or_dot(trimmed)
        end
    end
  end

  defp parent_or_dot(path) do
    case rsplit_once(path, "/") do
      {dir, _rest} -> dir
      nil -> "."
    end
  end

  defp find_wildcard_index(str) do
    str |> String.graphemes() |> Enum.find_index(&(&1 in ["*", "?", "["]))
  end

  # ── glob → regex (globset with literal_separator: true) ───────────────────

  defp compile_matcher(pattern) do
    body =
      pattern
      |> normalize_slashes()
      |> String.split("/")
      |> Enum.map_join("/", &segment/1)
      |> String.replace(@globstar <> "/", "(?:[^/]+/)*")
      |> String.replace("/" <> @globstar, "(?:/.+)?")
      |> String.replace(@globstar, ".*")

    Regex.compile!("\\A" <> body <> "\\z")
  end

  defp segment("**"), do: @globstar
  defp segment(seg), do: seg |> String.graphemes() |> translate([])

  defp translate([], acc), do: acc |> Enum.reverse() |> Enum.join()
  defp translate(["*" | rest], acc), do: translate(rest, ["[^/]*" | acc])
  defp translate(["?" | rest], acc), do: translate(rest, ["[^/]" | acc])

  defp translate(["[", "!" | rest], acc), do: take_class(rest, ["^", "["], acc)
  defp translate(["[" | rest], acc), do: take_class(rest, ["["], acc)

  defp translate([ch | rest], acc), do: translate(rest, [Regex.escape(ch) | acc])

  defp take_class([], class, acc), do: translate([], [Enum.join(Enum.reverse(class)) | acc])

  defp take_class(["]" | rest], class, acc),
    do: translate(rest, [Enum.join(Enum.reverse(["]" | class])) | acc])

  defp take_class([ch | rest], class, acc), do: take_class(rest, [ch | class], acc)

  defp rsplit_once(str, sep) do
    case :binary.matches(str, sep) do
      [] ->
        nil

      matches ->
        {start, len} = List.last(matches)
        {binary_part(str, 0, start), binary_part(str, start + len, byte_size(str) - start - len)}
    end
  end

  defp normalize_slashes(input), do: String.replace(input, "\\", "/")
end
