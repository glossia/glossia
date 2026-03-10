defmodule GlossiaAgent.Glob do
  @moduledoc """
  File walking and glob matching.
  Ported from agent/glob.ts / cli/internal/glossia/glob.go
  """

  @skip_dirs MapSet.new([".git", "node_modules"])

  @doc """
  Walk a directory tree recursively and return relative file paths.
  Skips `.git` and `node_modules` directories.
  """
  @spec walk_files(String.t()) :: [String.t()]
  def walk_files(root) do
    root
    |> do_walk([])
    |> Enum.map(&normalize_slashes(Path.relative_to(&1, root)))
    |> Enum.sort()
  end

  defp do_walk(current, acc) do
    case File.ls(current) do
      {:ok, entries} ->
        Enum.reduce(entries, acc, fn name, acc ->
          full = Path.join(current, name)

          cond do
            File.dir?(full) ->
              if MapSet.member?(@skip_dirs, name), do: acc, else: do_walk(full, acc)

            File.regular?(full) ->
              [full | acc]

            true ->
              acc
          end
        end)

      {:error, _} ->
        acc
    end
  end

  @doc "Convert a glob pattern to a compiled Regex."
  @spec glob_to_regex(String.t()) :: Regex.t()
  def glob_to_regex(pattern) do
    pattern
    |> normalize_slashes()
    |> do_glob_to_regex(0, "^")
    |> Kernel.<>("$")
    |> Regex.compile!()
  end

  defp do_glob_to_regex(pattern, i, acc) when i >= byte_size(pattern), do: acc

  defp do_glob_to_regex(pattern, i, acc) do
    char = String.at(pattern, i)

    case char do
      "*" ->
        next = String.at(pattern, i + 1)

        if next == "*" do
          next_next = String.at(pattern, i + 2)

          if next_next == "/" do
            do_glob_to_regex(pattern, i + 3, acc <> "(?:.*/)?")
          else
            do_glob_to_regex(pattern, i + 2, acc <> ".*")
          end
        else
          do_glob_to_regex(pattern, i + 1, acc <> "[^/]*")
        end

      "?" ->
        do_glob_to_regex(pattern, i + 1, acc <> "[^/]")

      "[" ->
        case :binary.match(pattern, "]", scope: {i + 1, byte_size(pattern) - i - 1}) do
          {close_idx, _} ->
            bracket = binary_part(pattern, i, close_idx - i + 1)
            do_glob_to_regex(pattern, close_idx + 1, acc <> bracket)

          :nomatch ->
            do_glob_to_regex(pattern, i + 1, acc <> "\\[")
        end

      c when c in ["\\", ".", "^", "$", "+", "(", ")", "{", "}", "|"] ->
        do_glob_to_regex(pattern, i + 1, acc <> "\\" <> c)

      c ->
        do_glob_to_regex(pattern, i + 1, acc <> c)
    end
  end

  @doc "Filter a list of file paths by a glob pattern."
  @spec glob_files(String.t(), [String.t()]) :: [String.t()]
  def glob_files(pattern, files) do
    re = glob_to_regex(pattern)
    Enum.filter(files, &Regex.match?(re, normalize_slashes(&1)))
  end

  @doc "Extract the non-glob prefix from a glob pattern (the base directory)."
  @spec glob_base(String.t()) :: String.t()
  def glob_base(pattern) do
    normalized = normalize_slashes(pattern)

    case find_first_wildcard(normalized) do
      nil ->
        dir = Path.dirname(normalized)
        if dir == ".", do: ".", else: normalize_slashes(dir)

      pos ->
        prefix = binary_part(normalized, 0, pos)
        last_slash = find_last_slash(prefix)

        if last_slash == nil, do: ".", else: binary_part(prefix, 0, last_slash)
    end
  end

  defp find_first_wildcard(pattern) do
    pattern
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.find_value(fn {ch, idx} ->
      if ch in ["*", "?", "["], do: idx, else: nil
    end)
  end

  defp find_last_slash(str) do
    str
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.reverse()
    |> Enum.find_value(fn {ch, idx} ->
      if ch == "/", do: idx, else: nil
    end)
  end

  defp normalize_slashes(input), do: String.replace(input, "\\", "/")
end
