defmodule GlossiaAgent.Setup.FrameworkHints do
  @moduledoc """
  Framework-aware localization hints used by setup generation and validation.

  Hints are detected deterministically from repository structure so we can
  enforce high-signal requirements (for example, Phoenix gettext catalogs)
  without relying only on LLM inference.
  """

  alias GlossiaAgent.Setup.FrameworkHints.Detectors.Phoenix

  @type hint :: %{
          framework: String.t(),
          summary: String.t(),
          required_sources: [String.t()]
        }

  @detectors [Phoenix]

  @spec detect([String.t()], %{optional(String.t()) => String.t()}) :: [hint()]
  def detect(tree, key_files) do
    @detectors
    |> Enum.map(& &1.detect(tree, key_files))
    |> Enum.filter(&is_map/1)
  end

  @spec required_sources([hint()]) :: [String.t()]
  def required_sources(hints) do
    hints
    |> Enum.flat_map(fn hint -> hint.required_sources || [] end)
    |> Enum.uniq()
  end

  @spec format_for_prompt([hint()]) :: String.t()
  def format_for_prompt(hints) do
    case required_sources(hints) do
      [] ->
        ""

      required ->
        lines =
          Enum.map_join(required, "\n", fn source ->
            "- Include a [[content]] entry with source matching `#{source}`"
          end)

        """
        Framework localization requirements:
        #{lines}
        """
    end
  end
end
