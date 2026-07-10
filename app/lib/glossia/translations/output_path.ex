defmodule Glossia.Translations.OutputPath do
  @moduledoc """
  Computes a translation's output path from the resolved frontmatter templates.

  Ported from the CLI (`cli/src/output.rs` + `cli/src/translate/output_path.rs`)
  so the server-side planner places translated files exactly where the CLI would.

  Template placeholders: `{lang}`, `{locale}`, `{relpath}`, `{basename}`, `{ext}`
  (`{lang}` and `{locale}` both expand to the locale). Backslashes are normalized
  to `/` and runs of slashes are collapsed.
  """

  @doc """
  Builds the output path for a source file at `locale`.

    * `source_target_template` - per-source mapped target (from `sources:` map values), or nil
    * `output_template` - the `output:` template, or nil
    * `target_path_template` - the `target_path:` template, or nil
    * `locale` - target locale
    * `rel_source` - source path relative to the match base (for `{relpath}`)
    * `rel_source_path` - source path relative to the repo root

  Returns `{:ok, path}` or `{:error, reason}` (when no template is available).
  """
  def build_output_path(
        source_target_template,
        output_template,
        target_path_template,
        locale,
        rel_source,
        rel_source_path
      ) do
    values = %{
      lang: locale,
      locale: locale,
      relpath: rel_source,
      basename: stem(rel_source_path),
      ext: extension(rel_source_path)
    }

    cond do
      is_binary(source_target_template) ->
        build_mapped_output_path(source_target_template, values, rel_source_path)

      is_binary(output_template) ->
        {:ok, expand_output(output_template, values)}

      is_binary(target_path_template) ->
        target_dir = expand_output(target_path_template, values)
        source_parent = rel_source_path |> Path.dirname() |> normalize_slashes()
        output_file = default_output_file(rel_source_path)

        output_path =
          if source_parent in ["", "."] do
            "#{target_dir}/#{output_file}"
          else
            "#{target_dir}/#{source_parent}/#{output_file}"
          end

        {:ok, normalize_slashes_collapsed(output_path)}

      true ->
        {:error, "frontmatter target_path or output is required"}
    end
  end

  @doc "Expands template placeholders and normalizes slashes."
  def expand_output(template, values) do
    template
    |> String.replace("{lang}", values.lang)
    |> String.replace("{locale}", values.locale)
    |> String.replace("{relpath}", String.replace(values.relpath, "\\", "/"))
    |> String.replace("{basename}", values.basename)
    |> String.replace("{ext}", values.ext)
    |> normalize_slashes_collapsed()
  end

  @doc "Collapses runs of `/` or `\\` into a single `/`."
  def normalize_slashes_collapsed(input), do: String.replace(input, ~r{[\\/]+}, "/")

  @doc "Replaces backslashes with forward slashes (no collapsing)."
  def normalize_slashes(input), do: String.replace(input, "\\", "/")

  defp build_mapped_output_path(template, values, rel_source_path) do
    expanded = expand_output(template, values)

    cond do
      String.contains?(expanded, "*") ->
        result =
          expanded
          |> String.replace("**", String.replace(values.relpath, "\\", "/"))
          |> String.replace("*", values.basename)
          |> normalize_slashes_collapsed()

        {:ok, result}

      Path.extname(expanded) != "" ->
        {:ok, expanded}

      true ->
        {:ok, normalize_slashes_collapsed("#{expanded}/#{default_output_file(rel_source_path)}")}
    end
  end

  defp default_output_file(rel_source_path) do
    if String.downcase(extension(rel_source_path)) == "pot" do
      "#{stem(rel_source_path)}.po"
    else
      Path.basename(rel_source_path)
    end
  end

  defp stem(path), do: Path.basename(path, Path.extname(path))

  defp extension(path), do: path |> Path.extname() |> String.trim_leading(".")
end
