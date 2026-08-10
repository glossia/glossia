defmodule Glossia.CredoChecks.NoTypeAnnotations do
  @moduledoc """
  Flags `@type` and `@spec` module attributes.

  This codebase does not use Elixir type annotations: types are conveyed
  through `@moduledoc`, function names, the function signatures themselves,
  and the test suite. See `AGENTS.md` (Type annotations) for the rationale.
  """

  use Credo.Check,
    id: "GL3001",
    base_priority: :high,
    tags: [:controversial, :style],
    explanations: [
      check: """
      `@type` and `@spec` module attributes are not used in this codebase.

      Types live in `@moduledoc`, function names, and the function
      signatures themselves. Adding them is not allowed.
      """
    ]

  alias Credo.SourceFile

  # Matches `@type` or `@spec` at the start of a line (possibly indented) and
  # followed by whitespace, an opening paren, or end-of-line. Anchoring the
  # suffix to those characters avoids false positives on identifiers such as
  # `@type_info` or `@spec_helper`.
  @annotation_regex ~r/^\s*@(?:type|spec)(?:\s|\(|$)/

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)

    source_file
    |> SourceFile.source()
    |> find_annotations()
    |> Enum.map(&issue_for(ctx, &1))
  end

  defp find_annotations(source) do
    source
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_no} ->
      if Regex.match?(@annotation_regex, line) do
        [{line_no, line}]
      else
        []
      end
    end)
  end

  defp issue_for(ctx, {line_no, line}) do
    format_issue(
      ctx,
      message: "Type annotations (`@type`, `@spec`) are not used in this codebase.",
      trigger: String.trim(line),
      line_no: line_no
    )
  end
end
