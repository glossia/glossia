defmodule GlossiaAgent.Actions.BuildPlan do
  @moduledoc """
  Jido Action: Build translation sources from parsed config.

  Takes the parsed GLOSSIA.md configuration and builds translation
  source entries with source paths, target languages, and output paths.
  """

  use Jido.Action,
    name: "build_plan",
    description: "Build translation sources from parsed GLOSSIA.md config",
    schema: [
      repo_path: [type: :string, required: true, doc: "Path to the root directory"],
      fallback_agent: [type: :any, required: true, doc: "Fallback LLM agent config"]
    ]

  alias GlossiaAgent.Plan

  @spec run(map(), map()) :: {:ok, map()}
  def run(params, _context) do
    translation_sources = Plan.Builder.build(params.repo_path, params.fallback_agent)
    {:ok, %{translation_sources: translation_sources}}
  end
end
