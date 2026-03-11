defmodule GlossiaAgent.Plan.Builder do
  @moduledoc """
  Translation plan building from GLOSSIA.md configuration.
  Ported from agent/plan.ts / cli/internal/glossia/plan.go
  """

  alias GlossiaAgent.Config.Parser
  alias GlossiaAgent.Config.LLMConfig
  alias GlossiaAgent.Format
  alias GlossiaAgent.Glob
  alias GlossiaAgent.Output
  alias GlossiaAgent.Plan.Types.{TranslationSource, TranslationOutput}

  @config_filenames ["GLOSSIA.md", "LANGUAGE.md"]

  @doc "Build translation sources from the root directory."
  @spec build(String.t()) :: [TranslationSource.t()]
  def build(root) do
    root_abs = Path.expand(root)

    content_files = discover_content(root_abs)
    entries = Parser.collect_entries(content_files)
    file_list = Glob.walk_files(root_abs)
    resolved = resolve_entries(root_abs, entries, file_list)

    resolved
    |> Enum.map(fn %{source_path: source_path, candidate: candidate} ->
      build_translation_source(root_abs, source_path, candidate, content_files)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1.path)
  end

  # -- Content discovery -------------------------------------------------------

  defp discover_content(root) do
    file_list = Glob.walk_files(root)

    content_paths =
      Enum.filter(file_list, fn file ->
        basename = Path.basename(file)
        basename in @config_filenames
      end)

    {files, _seen} =
      Enum.reduce(content_paths, {[], MapSet.new()}, fn rel_path, {acc, seen} ->
        abs_path = Path.join(root, rel_path)
        parsed = Parser.parse_content_file(abs_path)

        rel_dir = Path.relative_to(parsed.dir, root)

        if MapSet.member?(seen, rel_dir) do
          {acc, seen}
        else
          rel_dir_norm =
            rel_dir
            |> String.replace("\\", "/")
            |> String.replace_leading("./", "")

          depth =
            if rel_dir_norm in [".", ""] do
              0
            else
              rel_dir_norm |> String.split("/") |> length()
            end

          parsed = %{parsed | depth: depth}
          {[parsed | acc], MapSet.put(seen, rel_dir)}
        end
      end)

    files
    |> Enum.reverse()
    |> Enum.sort_by(& &1.depth)
  end

  # -- Entry resolution --------------------------------------------------------

  defp resolve_entries(root, entries, file_list) do
    candidates =
      Enum.reduce(entries, %{}, fn entry, acc ->
        {pattern, base_path} = entry_pattern(root, entry)
        matches = Glob.glob_files(pattern, file_list)
        excludes = resolve_excludes(root, entry, file_list)

        Enum.reduce(matches, acc, fn match, acc ->
          basename = Path.basename(match)

          if basename in @config_filenames || MapSet.member?(excludes, match) do
            acc
          else
            current = Map.get(acc, match)

            if current == nil || should_override?(current.entry, entry) do
              Map.put(acc, match, %{entry: entry, base_path: base_path})
            else
              acc
            end
          end
        end)
      end)

    candidates
    |> Enum.sort_by(fn {key, _} -> key end)
    |> Enum.map(fn {key, val} -> %{source_path: key, candidate: val} end)
  end

  defp should_override?(existing, candidate) do
    cond do
      candidate.origin_depth > existing.origin_depth -> true
      candidate.origin_depth == existing.origin_depth && candidate.index > existing.index -> true
      true -> false
    end
  end

  defp entry_pattern(root, entry) do
    rel_dir = Path.relative_to(entry.origin_dir, root)

    src = String.trim(entry.source || entry.path || "")
    prefix = if rel_dir != ".", do: rel_dir, else: ""

    pattern =
      if prefix != "" do
        "#{prefix}/#{src}" |> String.replace("\\", "/")
      else
        String.replace(src, "\\", "/")
      end

    base_path = Glob.glob_base(pattern)
    base_path = if base_path == ".", do: if(prefix != "", do: prefix, else: "."), else: base_path

    {pattern, base_path}
  end

  defp resolve_excludes(root, entry, file_list) do
    if entry.exclude == [] do
      MapSet.new()
    else
      rel_dir = Path.relative_to(entry.origin_dir, root)
      prefix = if rel_dir != ".", do: rel_dir, else: ""

      Enum.reduce(entry.exclude, MapSet.new(), fn pattern, acc ->
        scoped =
          if prefix != "" do
            "#{prefix}/#{pattern}" |> String.replace("\\", "/")
          else
            String.replace(pattern, "\\", "/")
          end

        Glob.glob_files(scoped, file_list)
        |> Enum.reduce(acc, &MapSet.put(&2, &1))
      end)
    end
  end

  # -- Translation source building ---------------------------------------------

  defp build_translation_source(root_abs, source_path, candidate, content_files) do
    source_abs_path = Path.join(root_abs, source_path)
    context_files = ancestors_for(source_abs_path, content_files)

    {context_parts, llm_cfg} =
      Enum.reduce(context_files, {[], %LLMConfig{}}, fn file, {parts, llm} ->
        parts =
          if String.trim(file.body) != "", do: parts ++ [file.body], else: parts

        llm = LLMConfig.merge(llm, file.llm)
        {parts, llm}
      end)

    agents = LLMConfig.resolve_agents(llm_cfg)
    translator = agents.translator

    rel_path =
      Path.relative_to(
        source_abs_path,
        Path.join(root_abs, candidate.base_path)
      )

    ext_with_dot = Path.extname(source_path)
    ext = String.trim_leading(ext_with_dot, ".")
    basename = Path.basename(source_path, ext_with_dot)

    if candidate.entry.targets == [] do
      nil
    else
      outputs =
        Enum.map(candidate.entry.targets, fn lang ->
          %TranslationOutput{
            language: lang,
            path:
              Output.expand(candidate.entry.output, %{
                lang: lang,
                rel_path: String.replace(rel_path, "\\", "/"),
                basename: basename,
                ext: ext
              })
          }
        end)

      %TranslationSource{
        path: source_path,
        format: Format.detect(source_path),
        context: Enum.join(context_parts, "\n\n"),
        translator: translator,
        outputs: outputs
      }
    end
  end

  defp ancestors_for(source_abs_path, content_files) do
    content_files
    |> Enum.filter(fn file ->
      source_str = String.replace(source_abs_path, "\\", "/")
      dir_str = String.replace(file.dir, "\\", "/")
      source_str == dir_str || String.starts_with?(source_str, dir_str <> "/")
    end)
    |> Enum.sort_by(& &1.depth)
  end
end
