defmodule GlossiaAgent.Plan.Types do
  @moduledoc """
  Type definitions for the translation plan.
  """

  alias GlossiaAgent.Config.LLMConfig.AgentConfig

  defmodule TranslationOutput do
    @moduledoc false
    defstruct [:language, :path]

    @type t :: %__MODULE__{
            language: String.t(),
            path: String.t()
          }
  end

  defmodule TranslationSource do
    @moduledoc false
    defstruct [
      :path,
      :format,
      :context,
      :translator,
      :outputs
    ]

    @type t :: %__MODULE__{
            path: String.t(),
            format: GlossiaAgent.Format.t(),
            context: String.t(),
            translator: AgentConfig.t(),
            outputs: [TranslationOutput.t()]
          }
  end

  @doc "Get the normalized language value for an output plan entry."
  @spec output_language(TranslationOutput.t()) :: String.t()
  def output_language(%TranslationOutput{language: language}) do
    trimmed = String.trim(language)
    if trimmed == "", do: "_", else: trimmed
  end
end
