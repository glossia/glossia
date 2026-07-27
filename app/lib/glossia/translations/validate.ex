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
  alias Glossia.Translations.PreservedTokens
  alias Glossia.Translations.Validate.Po

  # Cap untrusted repository check/validation commands (matches the CLI).
  @command_timeout_ms 600_000

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
    case content |> String.split("\n", parts: 2) |> List.first() |> String.trim() do
      "%{" <> _rest ->
        validate_nimble_publisher_frontmatter(content)

      first ->
        if first in ["---", "+++"] do
          case Frontmatter.parse_content(content) do
            {:ok, _parsed} -> :ok
            {:error, error} -> {:error, "markdown frontmatter invalid: #{error}"}
          end
        else
          :ok
        end
    end
  end

  defp validate_nimble_publisher_frontmatter(content) do
    case Frontmatter.split_markdown_frontmatter(content) do
      %{ok: true, frontmatter: frontmatter} ->
        frontmatter =
          frontmatter
          |> String.split("\n")
          |> Enum.drop(-1)
          |> Enum.join("\n")

        case Code.string_to_quoted(frontmatter) do
          {:ok, {:%{}, _, _}} ->
            :ok

          {:ok, _other} ->
            {:error, "markdown frontmatter invalid: expected an Elixir map"}

          {:error, error} ->
            {:error, "markdown frontmatter invalid: #{inspect(error)}"}
        end

      _ ->
        {:error, "markdown frontmatter invalid: expected a closing map and --- delimiter"}
    end
  end

  # ── preserve ────────────────────────────────────────────────────────────

  @doc "Resolves the preserve kinds: default set, `\"none\"` to disable, or the given list."
  defdelegate resolve_preserve(kinds), to: PreservedTokens, as: :resolve

  defp validate_preserve_step(_output, _source, []), do: :ok
  defp validate_preserve_step(output, source, kinds), do: validate_preserve(output, source, kinds)

  @doc "Fails unless placeholders, links, and code occur equally in source and output."
  def validate_preserve(output, source, kinds) do
    source_values = PreservedTokens.values(source, kinds)
    output_values = PreservedTokens.values(output, kinds)
    missing = frequency_difference(source_values, output_values)
    unexpected = frequency_difference(output_values, source_values)

    cond do
      missing != [] ->
        {:error, "preserved tokens missing from output: #{Jason.encode!(missing)}"}

      unexpected != [] ->
        {:error, "unexpected preserved tokens in output: #{Jason.encode!(unexpected)}"}

      true ->
        :ok
    end
  end

  defp frequency_difference(expected, actual) do
    actual_counts = Enum.frequencies(actual)

    expected
    |> Enum.frequencies()
    |> Enum.flat_map(fn {value, count} ->
      List.duplicate(value, max(count - Map.get(actual_counts, value, 0), 0))
    end)
    |> Enum.take(5)
  end

  # ── external ────────────────────────────────────────────────────────────

  defp validate_external(root, format, output, options) do
    cond do
      is_list(options[:validation]) and options[:validation] != [] ->
        run_validation_command(root, options[:validation], output, options)

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

    try do
      case MuonTrap.cmd("sh", ["-c", command],
             cd: root,
             stderr_to_stdout: true,
             into: "",
             timeout: @command_timeout_ms
           ) do
        {_out, 0} -> :ok
        {out, code} -> {:error, "external check failed: exit #{code}\n#{String.trim(out)}"}
      end
    after
      # Remove the ephemeral check file so it never lands in the translation PR
      # (collect_changes/1 gathers the .glossia tree as untracked).
      File.rm(tmp)
    end
  end

  @doc false
  def run_validation_command(root, [cmd | args], output, options) do
    with {:ok, doc} <-
           require_opt(
             options,
             :validation_doc_abs,
             "validation requires declaring document path"
           ),
         {:ok, source} <- require_opt(options, :source_abs, "validation requires source path"),
         {:ok, target} <- require_opt(options, :target_abs, "validation requires target path"),
         {:ok, locale} <- require_opt(options, :locale, "validation requires locale") do
      env = [
        {"GLOSSIA_SOURCE_PATH", to_string(source)},
        {"GLOSSIA_TARGET_PATH", to_string(target)},
        {"GLOSSIA_LOCALE", locale},
        {"GLOSSIA_DOC_PATH", to_string(doc)}
      ]

      with_candidate_at_target(target, output, fn ->
        case MuonTrap.cmd(cmd, args,
               cd: options[:validation_cwd] || root,
               env: env,
               stderr_to_stdout: true,
               into: "",
               timeout: @command_timeout_ms
             ) do
          {_out, 0} -> :ok
          {out, code} -> {:error, "validation failed: exit #{code}\n#{String.trim(out)}"}
        end
      end)
    end
  end

  defp with_candidate_at_target(target, output, validation) do
    previous =
      case File.read(target) do
        {:ok, content} -> {:present, content}
        {:error, :enoent} -> :absent
        {:error, reason} -> raise File.Error, reason: reason, action: "read", path: target
      end

    File.mkdir_p!(Path.dirname(target))
    File.write!(target, output)

    try do
      validation.()
    after
      restore_target!(target, previous)
    end
  end

  defp restore_target!(target, {:present, content}), do: File.write!(target, content)

  defp restore_target!(target, :absent) do
    case File.rm(target) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      {:error, reason} -> raise File.Error, reason: reason, action: "remove", path: target
    end
  end

  defp require_opt(options, key, message) do
    case options[key] do
      nil -> {:error, message}
      value -> {:ok, value}
    end
  end
end
