defmodule GlossiaAgent.Actions.BuildPlan do
  @moduledoc """
  Jido Action: Build translation sources from a localizable directory.

  Scans the provided directory for GLOSSIA.md / LANGUAGE.md config files
  and builds translation source entries with source paths, target
  languages, and output paths.
  """

  use Jido.Action,
    name: "build_plan",
    description: "Build translation sources from a localizable directory",
    schema: [
      repo_path: [type: :string, required: true, doc: "Path to the localizable directory"]
    ]

  alias GlossiaAgent.Plan

  @spec run(map(), map()) :: {:ok, map()}
  def run(params, _context) do
    # Input shape (params):
    # %{repo_path: "/repo/content"}
    translation_sources = Plan.Builder.build(params.repo_path)

    # Output shape merged into agent state:
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
