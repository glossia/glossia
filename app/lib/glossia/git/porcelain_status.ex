defmodule Glossia.Git.PorcelainStatus do
  @moduledoc """
  Parses `git status --porcelain` output into `%{path, status}` entries, where
  `status` is `"added" | "modified" | "deleted"`.

  Shared by `Glossia.Translations.RepositoryRun` and
  `Glossia.Projects.SetupHarness` so classification lives in one place.

  A rename (`R  old -> new`) expands into two entries — the old path deleted and
  the new path added — so callers building a tree don't leave the original file
  behind. A copy (`C  old -> new`) yields only the new path. Quoted paths (git's
  encoding for special characters) are decoded.
  """

  @doc "Parses porcelain output into a flat list of change entries (may repeat a path)."
  def parse(output) when is_binary(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.flat_map(&parse_line/1)
  end

  defp parse_line(line) when byte_size(line) >= 4 do
    code = String.slice(line, 0, 2)
    rest = (String.slice(line, 3..-1//1) || "") |> String.trim()

    cond do
      rest == "" -> []
      String.contains?(rest, " -> ") -> expand_rename(code, rest)
      true -> [%{path: unquote_path(rest), status: classify(code)}]
    end
  end

  defp parse_line(_line), do: []

  defp expand_rename(code, rest) do
    case String.split(rest, " -> ", parts: 2) do
      [old, new] ->
        old = unquote_path(String.trim(old))
        new = unquote_path(String.trim(new))

        if String.contains?(code, "R") do
          [%{path: old, status: "deleted"}, %{path: new, status: "added"}]
        else
          # Copy: the original is unchanged, only the new path is added.
          [%{path: new, status: "added"}]
        end

      _ ->
        [%{path: unquote_path(rest), status: classify(code)}]
    end
  end

  defp classify(code) do
    cond do
      String.contains?(code, "D") -> "deleted"
      String.contains?(code, "A") or code == "??" -> "added"
      true -> "modified"
    end
  end

  defp unquote_path(raw) do
    if String.starts_with?(raw, "\"") and String.ends_with?(raw, "\"") do
      case Jason.decode(raw) do
        {:ok, unquoted} when is_binary(unquoted) -> unquoted
        _ -> raw
      end
    else
      raw
    end
  end
end
