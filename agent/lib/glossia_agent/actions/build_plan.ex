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
      repo_path: [type: :string, required: true, doc: "Path to the root directory"]
    ]

  alias GlossiaAgent.Plan

  @spec run(map(), map()) :: {:ok, map()}
  def run(params, _context) do
    translation_sources = Plan.Builder.build(params.repo_path)

    # Jido actions return maps that are merged into agent state, so this is wrapped
    # under a key instead of returning a bare list.
    # Example:
    # %{
    #   translation_sources: [
    #     %GlossiaAgent.Plan.Types.TranslationSource{
    #       path: "docs/intro.md",
    #       outputs: [
    #         %GlossiaAgent.Plan.Types.TranslationOutput{
    #           language: "es",
    #           path: "docs/i18n/es/intro.md"
    #         }
    #       ]
    #     }
    #   ]
    # }
    {:ok, %{translation_sources: translation_sources}}
  end
end
