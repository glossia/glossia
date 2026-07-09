defmodule Glossia.Translations.Validate do
  @moduledoc """
  Validates translated output. Ported from the CLI (`cli/src/validate/*`):

    * syntax — JSON/YAML parse, PO structural validation, markdown frontmatter
    * preserve — placeholders/URLs/code that must survive translation
    * external — a declared validation command or a per-format shell check

  `validate_output/5` returns `:ok` or `{:error, message}`; the Engine feeds the
  message back into the next translation attempt.
  """

  alias Glossia.Translations.Frontmatter
  alias Glossia.Translations.Validate.Po

  @default_preserve ~w(code_blocks inline_code urls placeholders)
  @inline_code_regex ~r/`[^`\n]+`/
  @url_regex ~r/https?:\/\/[^\s\)"'<>]+/
  @placeholder_regex ~r/\{[^\s{}]+\}/

  @doc """
  Runs syntax, preserve, and external checks for `output` against `source`.

  `options` is a map: `:preserve`, `:check_cmd`, `:check_cmds`, `:validation`
  (argv), `:validation_cwd`, `:validation_doc_abs`, `:source_abs`, `:target_abs`,
  `:locale`. `root` is the repository root (for shell checks).
  """
  def validate_output(root, format, output, source, options \\ %{}) do
    with :ok <- validate_syntax(format, output, source),
         :ok <- validate_preserve_step(output, source, resolve_preserve(options[:preserve] || [])),
         :ok <- validate_external(root, format, output, options) do
      :ok
    end
  end

  # ── syntax ──────────────────────────────────────────────────────────────

  def validate_syntax("json", output, _source) do
    case Jason.decode(output) do
      {:ok, _value} -> :ok
      {:error, error} -> {:error, "invalid JSON: #{Exception.message(error)}"}
    end
  end

  def validate_syntax("yaml", output, _source) do
    case YamlElixir.read_from_string(output) do
      {:ok, _value} -> :ok
      {:error, error} -> {:error, "invalid YAML: #{inspect(error)}"}
    end
  end

  def validate_syntax("po", output, source), do: Po.validate_po(output, source)
  def validate_syntax("markdown", output, _source), do: validate_markdown(output)
  def validate_syntax("text", _output, _source), do: :ok

  defp validate_markdown(content) do
    case content |> String.split("\n", parts: 2) |> List.first() do
      nil ->
        :ok

      first ->
        if String.trim(first) in ["---", "+++"] do
          case Frontmatter.parse_content(content) do
            {:ok, _parsed} -> :ok
            {:error, error} -> {:error, "markdown frontmatter invalid: #{error}"}
          end
        else
          :ok
        end
    end
  end

  # ── preserve ────────────────────────────────────────────────────────────

  @doc "Resolves the preserve kinds: default set, `\"none\"` to disable, or the given list."
  def resolve_preserve([]), do: @default_preserve

  def resolve_preserve(kinds) do
    if Enum.any?(kinds, &(String.downcase(String.trim(&1)) == "none")) do
      []
    else
      kinds |> Enum.map(&String.downcase(String.trim(&1))) |> Enum.reject(&(&1 == ""))
    end
  end

  defp validate_preserve_step(_output, _source, []), do: :ok
  defp validate_preserve_step(output, source, kinds), do: validate_preserve(output, source, kinds)

  @doc "Fails if placeholders/URLs/code present in `source` are missing from `output`."
  def validate_preserve(output, source, kinds) do
    missing =
      source
      |> extract_preservables(kinds)
      |> Enum.reject(&String.contains?(output, &1))
      |> Enum.take(5)

    if missing == [] do
      :ok
    else
      {:error, "preserved tokens missing from output: #{Jason.encode!(missing)}"}
    end
  end

  defp extract_preservables(source, kinds) do
    {working, blocks} =
      if "code_blocks" in kinds, do: extract_code_blocks(source), else: {source, []}

    blocks
    |> maybe_add("inline_code" in kinds, working, @inline_code_regex)
    |> maybe_add("urls" in kinds, working, @url_regex)
    |> maybe_add("placeholders" in kinds, working, @placeholder_regex)
    |> Enum.uniq()
  end

  defp maybe_add(tokens, false, _text, _regex), do: tokens

  defp maybe_add(tokens, true, text, regex),
    do: tokens ++ (regex |> Regex.scan(text) |> Enum.map(&hd/1))

  defp extract_code_blocks(source), do: extract_code_blocks(source, [], [])

  defp extract_code_blocks(rest, stripped, blocks) do
    case :binary.match(rest, "```") do
      :nomatch ->
        {Enum.join(Enum.reverse([rest | stripped])), Enum.reverse(blocks)}

      {start, _len} ->
        before = binary_part(rest, 0, start)
        after_open = binary_part(rest, start + 3, byte_size(rest) - start - 3)

        case :binary.match(after_open, "```") do
          :nomatch ->
            tail = binary_part(rest, start, byte_size(rest) - start)
            {Enum.join(Enum.reverse([tail, before | stripped])), Enum.reverse(blocks)}

          {end_rel, _len} ->
            block_len = 3 + end_rel + 3
            block = binary_part(rest, start, block_len)
            new_rest = binary_part(rest, start + block_len, byte_size(rest) - start - block_len)
            extract_code_blocks(new_rest, [before | stripped], [block | blocks])
        end
    end
  end

  # ── external ────────────────────────────────────────────────────────────

  defp validate_external(root, format, output, options) do
    cond do
      is_list(options[:validation]) and options[:validation] != [] ->
        run_validation_command(root, options[:validation], options)

      true ->
        case select_check_command(format, options) do
          nil -> :ok
          command -> run_shell_check(root, command, output)
        end
    end
  end

  defp select_check_command(format, options) do
    (get_in(options, [:check_cmds, format]) || options[:check_cmd])
    |> case do
      value when is_binary(value) -> if String.trim(value) == "", do: nil, else: value
      _ -> nil
    end
  end

  @doc false
  def run_shell_check(root, command_template, content) do
    tmp_dir = Path.join([root, ".glossia", "tmp"])
    File.mkdir_p!(tmp_dir)
    tmp = Path.join(tmp_dir, "check-#{System.unique_integer([:positive])}.tmp")
    File.write!(tmp, content)
    command = String.replace(command_template, "{path}", tmp)

    case System.cmd("sh", ["-c", command], cd: root, stderr_to_stdout: true) do
      {_out, 0} -> :ok
      {out, code} -> {:error, "external check failed: exit #{code}\n#{String.trim(out)}"}
    end
  end

  @doc false
  def run_validation_command(root, [cmd | args], options) do
    with {:ok, doc} <- require_opt(options, :validation_doc_abs, "validation requires declaring document path"),
         {:ok, source} <- require_opt(options, :source_abs, "validation requires source path"),
         {:ok, target} <- require_opt(options, :target_abs, "validation requires target path"),
         {:ok, locale} <- require_opt(options, :locale, "validation requires locale") do
      env = [
        {"GLOSSIA_SOURCE_PATH", to_string(source)},
        {"GLOSSIA_TARGET_PATH", to_string(target)},
        {"GLOSSIA_LOCALE", locale},
        {"GLOSSIA_DOC_PATH", to_string(doc)}
      ]

      case System.cmd(cmd, args, cd: options[:validation_cwd] || root, env: env, stderr_to_stdout: true) do
        {_out, 0} -> :ok
        {out, code} -> {:error, "validation failed: exit #{code}\n#{String.trim(out)}"}
      end
    end
  end

  defp require_opt(options, key, message) do
    case options[key] do
      nil -> {:error, message}
      value -> {:ok, value}
    end
  end
end
