defmodule GlossiaAgent.Actions.BuildPlan do
  @moduledoc """
  Jido Action: Build translation plan from parsed config.

  Takes the parsed GLOSSIA.md configuration and builds a plan of
  source files, target languages, and output paths.
  """

  use Jido.Action,
    name: "build_plan",
    description: "Build a translation plan from parsed GLOSSIA.md config",
    schema: [
      repo_path: [type: :string, required: true, doc: "Path to the root directory"],
      fallback_agent: [type: :any, required: true, doc: "Fallback LLM agent config"]
    ]

  alias GlossiaAgent.Plan

  @spec run(map(), map()) :: {:ok, map()}
  def run(params, _context) do
    plan = Plan.Builder.build(params.repo_path, params.fallback_agent)
    translate_sources = Enum.filter(plan.sources, &(&1.kind == :translate))

    {:ok,
     %{
       plan: plan,
       translate_sources: translate_sources,
       total_pairs:
         Enum.reduce(translate_sources, 0, fn source, acc ->
           acc + length(source.outputs)
         end)
     }}
  end
end
