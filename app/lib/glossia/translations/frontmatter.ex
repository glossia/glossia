defmodule Glossia.Translations.Frontmatter do
  @moduledoc """
  Parses and resolves `GLOSSIA.md` frontmatter for the server-side planner.

  Ported from the CLI (`cli/src/config.rs`), covering the planning-relevant
  fields: `source_language`, `sources`/`targets`/`translate` rules, `output`/
  `target_path` templates, `exclude`/`preserve`, `frontmatter` mode, `prompt`,
  `check_cmd`/`check_cmds`, `retries`, `validation`, plus `locale` and `model`.

  The CLI's LLM-connection fields (provider/base_url/api_key/…) are intentionally
  omitted: server-side translation uses account-configured models via Condukt, so
  per-document connection config is not a thing here. Unknown keys are ignored.

  `sources`/`targets` mirror the Rust untagged enums as tagged tuples:
  `{:map, %{...}}` or `{:list, [...]}`.
  """

  alias __MODULE__

  defstruct locale: nil,
            source_language: nil,
            model: nil,
            validation: nil,
            sources: nil,
            targets: nil,
            target_path: nil,
            output: nil,
            translate: nil,
            exclude: nil,
            preserve: nil,
            frontmatter: nil,
            prompt: nil,
            check_cmd: nil,
            check_cmds: nil,
            retries: nil

  # Fields propagated by `merge/2` (matches the Rust merge macro; `locale` is not merged).
  @merge_fields ~w(source_language model validation sources targets target_path output
                   translate exclude preserve frontmatter prompt check_cmd check_cmds retries)a

  @default_retries 2

  @type t :: %Frontmatter{}

  @doc """
  Parses document content into `{:ok, %{frontmatter: t, body: binary}}`.

  Supports YAML (`---`) and TOML (`+++`) frontmatter fences; content without a
  fence yields default frontmatter and the trimmed content as the body.
  """
  def parse_content(content) do
    case lines(content) do
      [] ->
        {:ok, %{frontmatter: %Frontmatter{}, body: ""}}

      [first | _] = ls ->
        marker = String.trim(first)

        if marker not in ["---", "+++"] do
          {:ok, %{frontmatter: %Frontmatter{}, body: String.trim(content)}}
        else
          parse_fenced(ls, marker)
        end
    end
  end

  defp parse_fenced(ls, marker) do
    case find_closing(ls, marker) do
      nil ->
        {:error, "frontmatter start found but no closing #{marker}"}

      end_idx ->
        raw = ls |> Enum.slice(1, max(end_idx - 1, 0)) |> Enum.join("\n")
        body = ls |> Enum.drop(end_idx + 1) |> Enum.join("\n") |> String.trim()

        with {:ok, map} <- decode_frontmatter(marker, raw) do
          {:ok, %{frontmatter: from_map(map), body: body}}
        end
    end
  end

  @doc """
  Splits leading frontmatter from a document, preserving the fence markers.

  Returns `%{frontmatter: binary, body: binary, ok: boolean}`. Used when
  translating with `frontmatter: preserve` so the fence is re-attached verbatim.
  """
  def split_markdown_frontmatter(content) do
    case lines(content) do
      [] ->
        %{frontmatter: "", body: "", ok: false}

      [first | _] = ls ->
        marker = String.trim(first)

        cond do
          marker not in ["---", "+++"] ->
            %{frontmatter: "", body: content, ok: false}

          is_nil(find_closing(ls, marker)) ->
            %{frontmatter: "", body: content, ok: false}

          true ->
            end_idx = find_closing(ls, marker)
            fm = ls |> Enum.slice(0, end_idx + 1) |> Enum.join("\n")
            body = ls |> Enum.drop(end_idx + 1) |> Enum.join("\n")
            %{frontmatter: fm, body: body, ok: true}
        end
    end
  end

  @doc "Overlays non-nil fields of `other` onto `base` (child-wins inheritance)."
  def merge(%Frontmatter{} = base, %Frontmatter{} = other) do
    Enum.reduce(@merge_fields, base, fn field, acc ->
      case Map.get(other, field) do
        nil -> acc
        value -> Map.put(acc, field, value)
      end
    end)
  end

  @doc "source_language, defaulting to `\"en\"`."
  def source_language(%Frontmatter{source_language: nil}), do: "en"
  def source_language(%Frontmatter{source_language: value}), do: value

  @doc "frontmatter handling mode, defaulting to `:preserve`."
  def frontmatter_mode(%Frontmatter{frontmatter: nil}), do: :preserve
  def frontmatter_mode(%Frontmatter{frontmatter: mode}), do: mode

  @doc "targets as a `%{locale => language}` map."
  def targets(%Frontmatter{targets: spec}), do: spec_as_map(spec)

  @doc "Whether the document declares a non-empty `sources`."
  def has_sources?(%Frontmatter{sources: {:map, m}}), do: map_size(m) > 0
  def has_sources?(%Frontmatter{sources: {:list, l}}), do: l != []
  def has_sources?(%Frontmatter{sources: _}), do: false

  @doc "Whether the document declares non-empty `translate` rules."
  def has_translation_rules?(%Frontmatter{translate: [_ | _]}), do: true
  def has_translation_rules?(%Frontmatter{translate: _}), do: false

  @doc """
  Resolves the document into a list of concrete translate rules.

  Returns `{:ok, [rule]}` where each `rule` is a map with `:sources`
  (`[%{pattern, target_template}]`), `:targets` (`%{locale => language}`),
  `:output`, `:target_path`, `:exclude`, `:preserve`, `:frontmatter`, `:prompt`,
  `:check_cmd`, `:check_cmds`, `:retries`, and `:validation`. Mirrors
  `Frontmatter::translation_rules` in the CLI.
  """
  def translation_rules(%Frontmatter{translate: rules} = fm) when is_list(rules) do
    Enum.reduce_while(rules, {:ok, []}, fn rule, {:ok, acc} ->
      case resolve_rule(fm, rule) do
        {:ok, resolved} -> {:cont, {:ok, acc ++ [resolved]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  def translation_rules(%Frontmatter{} = fm) do
    sources = spec_into_mappings(fm.sources)

    cond do
      sources == [] ->
        {:ok, []}

      map_size(targets(fm)) == 0 ->
        {:error, "frontmatter targets are required when sources are configured"}

      true ->
        with {:ok, validation} <- validate_command_argv(fm.validation) do
          {:ok,
           [
             %{
               sources: sources,
               targets: targets(fm),
               output: fm.output,
               target_path: fm.target_path,
               exclude: fm.exclude || [],
               preserve: fm.preserve || [],
               frontmatter: frontmatter_mode(fm),
               prompt: fm.prompt,
               check_cmd: fm.check_cmd,
               check_cmds: fm.check_cmds || %{},
               retries: fm.retries || @default_retries,
               validation: validation
             }
           ]}
        end
    end
  end

  defp resolve_rule(%Frontmatter{} = fm, rule) do
    patterns = (rule.sources || []) ++ List.wrap(rule.source)

    if patterns == [] do
      {:error, "translate rule requires source or sources"}
    else
      targets = spec_as_map(rule.targets) |> fallback_map(targets(fm))

      if map_size(targets) == 0 do
        {:error, "translate rule requires targets"}
      else
        with {:ok, validation} <- validate_command_argv(rule.validation || fm.validation) do
          {:ok,
           %{
             sources: Enum.map(patterns, &%{pattern: &1, target_template: nil}),
             targets: targets,
             output: rule.output || fm.output,
             target_path: rule.target_path || fm.target_path,
             exclude: rule.exclude || fm.exclude || [],
             preserve: rule.preserve || fm.preserve || [],
             frontmatter: rule.frontmatter || frontmatter_mode(fm),
             prompt: rule.prompt || fm.prompt,
             check_cmd: rule.check_cmd || fm.check_cmd,
             check_cmds: rule.check_cmds || fm.check_cmds || %{},
             retries: rule.retries || fm.retries || @default_retries,
             validation: validation
           }}
        end
      end
    end
  end

  defp fallback_map(map, _fallback) when map_size(map) > 0, do: map
  defp fallback_map(_map, fallback), do: fallback

  # ── spec (sources/targets) helpers ────────────────────────────────────────

  defp spec_as_map(nil), do: %{}
  defp spec_as_map({:map, m}), do: m
  defp spec_as_map({:list, l}), do: Map.new(l, &{&1, &1})

  # Sources become an ordered list of {pattern, target_template}. Map entries are
  # sorted by pattern to match the CLI's BTreeMap ordering (deterministic output).
  defp spec_into_mappings(nil), do: []

  defp spec_into_mappings({:map, m}),
    do:
      m
      |> Enum.sort_by(fn {pattern, _} -> pattern end)
      |> Enum.map(fn {pattern, template} -> %{pattern: pattern, target_template: template} end)

  defp spec_into_mappings({:list, l}),
    do: Enum.map(l, &%{pattern: &1, target_template: nil})

  defp validate_command_argv(nil), do: {:ok, nil}

  defp validate_command_argv([]),
    do: {:error, "validation must contain at least one argument"}

  defp validate_command_argv(argv) when is_list(argv) do
    if Enum.any?(argv, &(String.trim(&1) == "")) do
      {:error, "validation arguments must be non-empty"}
    else
      {:ok, argv}
    end
  end

  # ── map → struct decoding ─────────────────────────────────────────────────

  defp from_map(map) do
    %Frontmatter{
      locale: string_field(map["locale"]),
      source_language: string_field(map["source_language"]),
      model: string_field(map["model"]),
      validation: string_list(map["validation"]),
      sources: parse_spec(map["sources"]),
      targets: parse_spec(map["targets"]),
      target_path: string_field(map["target_path"]),
      output: string_field(map["output"]),
      translate: parse_translate(map["translate"]),
      exclude: string_list(map["exclude"]),
      preserve: string_list(map["preserve"]),
      frontmatter: parse_mode(map["frontmatter"]),
      prompt: string_field(map["prompt"]),
      check_cmd: string_field(map["check_cmd"]),
      check_cmds: string_map(map["check_cmds"]),
      retries: int_field(map["retries"])
    }
  end

  defp parse_translate(list) when is_list(list), do: Enum.map(list, &parse_rule/1)
  defp parse_translate(_), do: nil

  defp parse_rule(rule) when is_map(rule) do
    %{
      source: string_field(rule["source"]),
      sources: string_list(rule["sources"]),
      targets: parse_spec(rule["targets"]),
      output: string_field(rule["output"]),
      target_path: string_field(rule["target_path"]),
      exclude: string_list(rule["exclude"]),
      preserve: string_list(rule["preserve"]),
      frontmatter: parse_mode(rule["frontmatter"]),
      prompt: string_field(rule["prompt"]),
      check_cmd: string_field(rule["check_cmd"]),
      check_cmds: string_map(rule["check_cmds"]),
      retries: int_field(rule["retries"]),
      validation: string_list(rule["validation"])
    }
  end

  defp parse_rule(_), do: %{source: nil, sources: nil, targets: nil}

  defp parse_spec(map) when is_map(map),
    do: {:map, Map.new(map, fn {k, v} -> {to_string(k), to_string(v)} end)}

  defp parse_spec(list) when is_list(list), do: {:list, Enum.map(list, &to_string/1)}
  defp parse_spec(_), do: nil

  defp parse_mode("preserve"), do: :preserve
  defp parse_mode("translate"), do: :translate
  defp parse_mode(_), do: nil

  defp string_field(value) when is_binary(value), do: value
  defp string_field(_), do: nil

  defp string_list(list) when is_list(list), do: Enum.map(list, &to_string/1)
  defp string_list(_), do: nil

  defp string_map(map) when is_map(map),
    do: Map.new(map, fn {k, v} -> {to_string(k), to_string(v)} end)

  defp string_map(_), do: nil

  defp int_field(value) when is_integer(value), do: value
  defp int_field(_), do: nil

  # ── Rust `str::lines()`-equivalent splitter (for join fidelity) ────────────

  defp lines(content) do
    parts = String.split(content, "\n")
    parts = if String.ends_with?(content, "\n"), do: Enum.drop(parts, -1), else: parts
    Enum.map(parts, &String.trim_trailing(&1, "\r"))
  end

  defp find_closing(ls, marker) do
    case ls |> Enum.drop(1) |> Enum.find_index(&(String.trim(&1) == marker)) do
      nil -> nil
      idx -> idx + 1
    end
  end

  defp decode_frontmatter(_marker, ""), do: {:ok, %{}}

  defp decode_frontmatter("---", raw) do
    case YamlElixir.read_from_string(raw) do
      {:ok, map} when is_map(map) -> {:ok, map}
      {:ok, _other} -> {:ok, %{}}
      {:error, error} -> {:error, "invalid YAML frontmatter: #{inspect(error)}"}
    end
  end

  defp decode_frontmatter("+++", raw) do
    case Toml.decode(raw) do
      {:ok, map} -> {:ok, map}
      {:error, error} -> {:error, "invalid TOML frontmatter: #{inspect(error)}"}
    end
  end
end
