defmodule GlossiaAgent.Actions.ParseConfig do
  @moduledoc """
  Jido Action: Build the fallback LLM agent configuration.

  Constructs the fallback AgentConfig from the provided API key and model.
  This config is used by the plan builder when no per-source LLM configuration
  is found in GLOSSIA.md.
  """

  use Jido.Action,
    name: "parse_config",
    description: "Build fallback LLM agent configuration",
    schema: [
      minimax_api_key: [type: :string, required: true, doc: "Fallback MiniMax API key"],
      model: [type: :string, default: "MiniMax-M2.5", doc: "Fallback LLM model name"]
    ]

  alias GlossiaAgent.Config

  @spec run(map(), map()) :: {:ok, map()}
  def run(params, _context) do
    fallback_agent = Config.LLMConfig.build_fallback_agent(params.minimax_api_key, params.model)
    {:ok, %{fallback_agent: fallback_agent}}
  end
end
