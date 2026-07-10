defmodule Glossia.Translations.Planner do
  @moduledoc """
  Builds the translation plan for a checked-out repository.

  Ported from the CLI (`cli/src/translate/plan.rs`). For every translation root it
  resolves the frontmatter chain, expands the source globs against the repo, and
  for each (source file × target locale) emits a work item describing what to
  translate and where to write it. The items feed `Glossia.Translations.Workflow`.

  A work item is a map with:

    * `:source_abs` / `:source_path` — absolute + repo-relative source location
    * `:output_abs` / `:output_path` — absolute + repo-relative destination
    * `:locale` / `:language` / `:source_language`
    * `:format` — detected from the output path
    * `:frontmatter_mode` (`:preserve`/`:translate`), `:preserve`, `:prompt`,
      `:check_cmd`, `:check_cmds`, `:retries`
    * `:validation` (argv) / `:validation_relative_path`
    * `:model` — the resolved per-scope model (locale overlay overrides the chain)
    * `:context_body` / `:locale_override_body` — resolved guidance
  """

  alias Glossia.Translations.Chain
  alias Glossia.Translations.Format
  alias Glossia.Translations.Frontmatter
  alias Glossia.Translations.Glob
  alias Glossia.Translations.OutputPath

  @doc """
  Builds the plan for `root`, optionally filtered to a single `locale`.

  Returns `{:ok, [work_item]}` sorted by `{source_path, locale}`, or `{:error, reason}`.
  """
  def build_plan(root, locale_filter \\ nil) do
    root = Path.expand(root)

    try do
      with {:ok, roots} <- Chain.find_translation_roots(root) do
        items = Enum.flat_map(roots, &plan_root(&1, root, locale_filter))
        {:ok, Enum.sort_by(items, &{&1.source_path, &1.locale})}
      end
    catch
      {:plan_error, reason} -> {:error, reason}
    end
  end

  defp plan_root(translation_root, root, locale_filter) do
    resolved = unwrap(Chain.resolve_chain(translation_root, root))
    rules = unwrap(Frontmatter.translation_rules(resolved.merged_frontmatter))

    if rules == [] do
      []
    else
      file_list = Glob.walk_files(translation_root)
      Enum.flat_map(rules, &plan_rule(&1, translation_root, root, locale_filter, file_list))
    end
  end

  defp plan_rule(rule, translation_root, root, locale_filter, file_list) do
    excludes = collect_excludes(rule.exclude, file_list)

    Enum.flat_map(rule.sources, fn source ->
      pattern_base = Glob.glob_base(source.pattern)

      source.pattern
      |> Glob.glob_files(file_list)
      |> Enum.reject(&(glossia_document?(&1) or &1 in excludes))
      |> Enum.flat_map(
        &plan_source(&1, source, pattern_base, rule, translation_root, root, locale_filter)
      )
    end)
  end

  defp plan_source(matched, source, pattern_base, rule, translation_root, root, locale_filter) do
    source_abs = Path.join(translation_root, matched)
    source_dir = Path.dirname(source_abs)
    source_path = relative_to_root(root, source_abs)
    scoped_rel_source = relative_to_glob_base(translation_root, pattern_base, source_abs)
    resolved = unwrap(Chain.resolve_chain(source_dir, root))
    effective_targets = effective_targets(resolved.merged_frontmatter, rule.targets)

    effective_targets
    |> Enum.sort_by(fn {locale, _language} -> locale end)
    |> Enum.filter(fn {locale, _language} -> is_nil(locale_filter) or locale_filter == locale end)
    |> Enum.map(fn {locale, language} ->
      build_item(%{
        locale: locale,
        language: language,
        source: source,
        rule: rule,
        resolved: resolved,
        source_dir: source_dir,
        source_abs: source_abs,
        source_path: source_path,
        scoped_rel_source: scoped_rel_source,
        translation_root: translation_root,
        root: root
      })
    end)
  end

  defp build_item(ctx) do
    override = unwrap(Chain.load_locale_override(ctx.source_dir, ctx.root, ctx.locale))
    declared_validation = override.validation || ctx.resolved.validation

    output_rel =
      unwrap(
        OutputPath.build_output_path(
          ctx.source.target_template,
          ctx.rule.output,
          ctx.rule.target_path,
          ctx.locale,
          ctx.scoped_rel_source,
          ctx.scoped_rel_source
        )
      )

    output_abs = Path.join(ctx.translation_root, output_rel)

    %{
      source_abs: ctx.source_abs,
      source_path: ctx.source_path,
      output_abs: output_abs,
      output_path: relative_to_root(ctx.root, output_abs),
      locale: ctx.locale,
      language: ctx.language,
      source_language: Frontmatter.source_language(ctx.resolved.merged_frontmatter),
      format: Format.detect(output_rel),
      frontmatter_mode: ctx.rule.frontmatter,
      preserve: ctx.rule.preserve,
      prompt: ctx.rule.prompt,
      check_cmd: ctx.rule.check_cmd,
      check_cmds: ctx.rule.check_cmds,
      validation: declared_validation && declared_validation.argv,
      validation_relative_path: declared_validation && declared_validation.relative_path,
      retries: ctx.rule.retries,
      model: override.model || ctx.resolved.merged_frontmatter.model,
      context_body: ctx.resolved.merged_body,
      locale_override_body: override.merged_body
    }
  end

  defp effective_targets(merged_frontmatter, rule_targets) do
    case Frontmatter.targets(merged_frontmatter) do
      targets when map_size(targets) == 0 -> rule_targets
      targets -> targets
    end
  end

  defp collect_excludes(patterns, file_list) do
    patterns
    |> Enum.flat_map(&Glob.glob_files(&1, file_list))
    |> Enum.uniq()
  end

  defp glossia_document?(path) do
    path == "GLOSSIA.md" or String.ends_with?(path, "/GLOSSIA.md") or
      String.starts_with?(path, "GLOSSIA/") or String.contains?(path, "/GLOSSIA/")
  end

  defp relative_to_glob_base(translation_root, ".", source_abs),
    do: relative_to_root(translation_root, source_abs)

  defp relative_to_glob_base(translation_root, pattern_base, source_abs) do
    base_abs = Path.join(translation_root, pattern_base)
    rel = Path.relative_to(Path.expand(source_abs), Path.expand(base_abs)) |> normalize_slashes()
    if rel == "" or rel == ".", do: ".", else: rel
  end

  defp relative_to_root(root, path) do
    Path.relative_to(Path.expand(path), Path.expand(root)) |> normalize_slashes()
  end

  defp normalize_slashes(input), do: String.replace(input, "\\", "/")

  defp unwrap({:ok, value}), do: value
  defp unwrap({:error, reason}), do: throw({:plan_error, reason})
end
