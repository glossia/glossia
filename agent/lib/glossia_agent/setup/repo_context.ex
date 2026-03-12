defmodule GlossiaAgent.Setup.RepoContext do
  @moduledoc """
  Gathers repository context for GLOSSIA.md generation.

  Walks the repository tree, reads key files, and detects patterns
  to provide the LLM with sufficient context to produce a useful
  GLOSSIA.md configuration.
  """

  alias GlossiaAgent.Setup.FrameworkHints

  @max_file_size 8_192
  @max_tree_entries 500

  @key_files ~w(
    README.md
    readme.md
    README
    package.json
    Cargo.toml
    go.mod
    mix.exs
    pyproject.toml
    setup.py
    setup.cfg
    Gemfile
    composer.json
    pom.xml
    build.gradle
    build.gradle.kts
    pubspec.yaml
    deno.json
    deno.jsonc
    tsconfig.json
    .gitignore
    GLOSSIA.md
  )

  @i18n_indicators ~w(
    i18n
    l10n
    locale
    locales
    translations
    messages
    lang
    languages
    intl
  )

  @doc """
  Gather context from a repository path.

  Returns a map with:
  - `:tree` - flat list of relative file paths
  - `:key_files` - map of filename => content for key project files
  - `:i18n_dirs` - directories that look like i18n/locale directories
  - `:content_dirs` - directories containing markdown/content files
  - `:framework_hints` - deterministic framework requirements for localization
  - `:has_glossia_md` - whether GLOSSIA.md already exists
  """
  @spec gather(String.t()) :: map()
  def gather(repo_path) do
    tree = build_tree(repo_path)
    key_file_contents = read_key_files(repo_path, tree)
    i18n_dirs = detect_i18n_dirs(tree)
    content_dirs = detect_content_dirs(tree)
    framework_hints = FrameworkHints.detect(tree, key_file_contents)
    has_glossia_md = Enum.any?(tree, &(Path.basename(&1) == "GLOSSIA.md"))

    %{
      tree: tree,
      key_files: key_file_contents,
      i18n_dirs: i18n_dirs,
      content_dirs: content_dirs,
      framework_hints: framework_hints,
      has_glossia_md: has_glossia_md
    }
  end

  @doc """
  Format the gathered context into a text block for the LLM prompt.
  """
  @spec format_context(map()) :: String.t()
  def format_context(context) do
    sections = []

    # Tree listing (truncated)
    tree_lines =
      context.tree
      |> Enum.take(@max_tree_entries)
      |> Enum.join("\n")

    truncated_note =
      if length(context.tree) > @max_tree_entries,
        do: "\n... (#{length(context.tree) - @max_tree_entries} more files)",
        else: ""

    sections = sections ++ ["## Repository file tree\n\n```\n#{tree_lines}#{truncated_note}\n```"]

    # Key files
    key_file_sections =
      context.key_files
      |> Enum.sort_by(fn {name, _} -> name end)
      |> Enum.map(fn {name, content} ->
        "## #{name}\n\n```\n#{content}\n```"
      end)

    sections = sections ++ key_file_sections

    # I18n directories
    sections =
      if context.i18n_dirs != [] do
        dirs = Enum.join(context.i18n_dirs, ", ")
        sections ++ ["## Detected i18n/locale directories\n\n#{dirs}"]
      else
        sections
      end

    # Framework hints
    sections =
      if context.framework_hints != [] do
        lines =
          Enum.map_join(context.framework_hints, "\n", fn hint ->
            required =
              if hint.required_sources == [] do
                "none"
              else
                Enum.join(hint.required_sources, ", ")
              end

            "- #{hint.framework}: #{hint.summary}; required sources: #{required}"
          end)

        sections ++ ["## Framework localization hints\n\n#{lines}"]
      else
        sections
      end

    Enum.join(sections, "\n\n")
  end

  defp build_tree(repo_path) do
    GlossiaAgent.Glob.walk_files(repo_path)
    |> Enum.map(&Path.relative_to(&1, repo_path))
    |> Enum.sort()
  end

  defp read_key_files(repo_path, tree) do
    tree
    |> Enum.filter(fn rel_path ->
      basename = Path.basename(rel_path)
      # Only read key files at root or one level deep
      depth = rel_path |> Path.split() |> length()
      basename in @key_files && depth <= 2
    end)
    |> Enum.reduce(%{}, fn rel_path, acc ->
      abs_path = Path.join(repo_path, rel_path)

      case File.stat(abs_path) do
        {:ok, %{size: size}} when size <= @max_file_size ->
          case File.read(abs_path) do
            {:ok, content} ->
              if String.valid?(content) do
                Map.put(acc, rel_path, content)
              else
                acc
              end

            _ ->
              acc
          end

        _ ->
          acc
      end
    end)
  end

  defp detect_i18n_dirs(tree) do
    tree
    |> Enum.map(&Path.dirname/1)
    |> Enum.uniq()
    |> Enum.filter(fn dir ->
      parts = Path.split(dir)

      Enum.any?(parts, fn part ->
        normalized = String.downcase(part)
        Enum.any?(@i18n_indicators, &(normalized == &1 || String.contains?(normalized, &1)))
      end)
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp detect_content_dirs(tree) do
    content_extensions = ~w(.md .mdx .json .yaml .yml .po .pot)

    tree
    |> Enum.filter(fn path ->
      ext = Path.extname(path)
      ext in content_extensions
    end)
    |> Enum.map(&Path.dirname/1)
    |> Enum.frequencies()
    |> Enum.filter(fn {_dir, count} -> count >= 2 end)
    |> Enum.map(fn {dir, _} -> dir end)
    |> Enum.sort()
  end
end
