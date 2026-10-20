defmodule Glossia.Git.PorcelainStatus do
  @moduledoc """
  Parses `git status --porcelain` output into `%{path, status}` entries, where
  `status` is `"added" | "modified" | "deleted"`.

  Used by `Glossia.Translations.RepositoryRun` (and any downstream build that
  wants the same classification logic — the setup harness has moved out of the
  repository).

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

  @doc "Parses porcelain v1 -z output without interpreting or trimming filenames."
  def parse_z(""), do: {:ok, []}

  def parse_z(output) when is_binary(output),
    do: parse_z_records(:binary.split(output, <<0>>, [:global]), [])

  defp parse_z_records([""], acc), do: {:ok, Enum.reverse(acc)}

  # In -z mode Git puts the destination first and the original path in a
  # second NUL-terminated field. Neither field is quoted or escaped.
  defp parse_z_records([<<x, y, 32, path::binary>>, original | rest], acc)
       when (x in [?R, ?C] or y in [?R, ?C]) and path != "" and original != "" do
    changes =
      if x == ?R or y == ?R do
        [%{path: path, status: "added"}, %{path: original, status: "deleted"} | acc]
      else
        [%{path: path, status: "added"} | acc]
      end

    parse_z_records(rest, changes)
  end

  defp parse_z_records([<<x, y, 32, path::binary>> | rest], acc)
       when x not in [?R, ?C] and y not in [?R, ?C] and path != "" do
    parse_z_records(rest, [%{path: path, status: classify(<<x, y>>)} | acc])
  end

  defp parse_z_records(_records, _acc), do: {:error, :incomplete_status}

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
