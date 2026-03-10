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
  alias GlossiaAgent.Plan.Types.{Plan, SourcePlan, OutputPlan}

  @config_filenames ["GLOSSIA.md", "LANGUAGE.md"]

  @doc "Build a translation plan from the repo root."
  @spec build(String.t(), LLMConfig.AgentConfig.t()) :: Plan.t()
  def build(root, fallback_agent) do
    root_abs = Path.expand(root)

    content_files = discover_content(root_abs)
    entries = Parser.collect_entries(content_files)
    file_list = Glob.walk_files(root_abs)
    resolved = resolve_entries(root_abs, entries, file_list)

    sources =
      resolved
      |> Enum.map(fn %{source_path: source_path, candidate: candidate} ->
        build_source_plan(root_abs, source_path, candidate, content_files, fallback_agent)
      end)
      |> Enum.sort_by(& &1.source_path)

    %Plan{root: root_abs, content_files: content_files, sources: sources}
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

  # -- Source plan building ----------------------------------------------------

  defp build_source_plan(root_abs, source_path, candidate, content_files, fallback_agent) do
    abs_path = Path.join(root_abs, source_path)
    context_files = ancestors_for(abs_path, content_files)

    is_translate = candidate.entry.targets != []
    kind = if is_translate, do: :translate, else: :revisit

    {context_bodies, context_paths, llm_cfg} =
      Enum.reduce(context_files, {[], [], %LLMConfig{}}, fn file, {bodies, paths, llm} ->
        bodies =
          if String.trim(file.body) != "", do: bodies ++ [file.body], else: bodies

        paths =
          if String.trim(file.body) != "", do: paths ++ [file.path], else: paths

        llm = LLMConfig.merge(llm, file.llm)
        {bodies, paths, llm}
      end)

    has_llm_config =
      String.trim(llm_cfg.provider) != "" ||
        String.trim(llm_cfg.translator_model) != "" ||
        llm_cfg.agents != []

    translator =
      if has_llm_config do
        agents = LLMConfig.resolve_agents(llm_cfg)
        agents.translator
      else
        fallback_agent
      end

    rel_path =
      Path.relative_to(
        abs_path,
        Path.join(root_abs, candidate.base_path)
      )

    ext_with_dot = Path.extname(source_path)
    ext = String.trim_leading(ext_with_dot, ".")
    basename = Path.basename(source_path, ext_with_dot)

    outputs =
      if is_translate do
        Enum.map(candidate.entry.targets, fn lang ->
          %OutputPlan{
            lang: lang,
            output_path:
              Output.expand(candidate.entry.output, %{
                lang: lang,
                rel_path: String.replace(rel_path, "\\", "/"),
                basename: basename,
                ext: ext
              })
          }
        end)
      else
        if String.trim(candidate.entry.output) == "" do
          [%OutputPlan{lang: "", output_path: source_path}]
        else
          [
            %OutputPlan{
              lang: "",
              output_path:
                Output.expand(candidate.entry.output, %{
                  lang: "",
                  rel_path: String.replace(rel_path, "\\", "/"),
                  basename: basename,
                  ext: ext
                })
            }
          ]
        end
      end

    %SourcePlan{
      source_path: source_path,
      abs_path: abs_path,
      base_path: candidate.base_path,
      rel_path: rel_path,
      format: Format.detect(source_path),
      kind: kind,
      entry: candidate.entry,
      context_bodies: context_bodies,
      context_paths: context_paths,
      translator: translator,
      outputs: outputs
    }
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
