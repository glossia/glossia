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
      :frontmatter,
      :translator,
      :outputs
    ]

    @type t :: %__MODULE__{
            path: String.t(),
            format: GlossiaAgent.Format.t(),
            context: String.t(),
            frontmatter: String.t(),
            translator: AgentConfig.t(),
            outputs: [TranslationOutput.t()]
          }
  end

  @doc "Get the language key for an output plan entry."
  @spec output_language_key(TranslationOutput.t()) :: String.t()
  def output_language_key(%TranslationOutput{language: language}) do
    trimmed = String.trim(language)
    if trimmed == "", do: "_", else: trimmed
  end
end
