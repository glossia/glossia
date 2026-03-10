defmodule GlossiaAgent.Plan.Types do
  @moduledoc """
  Type definitions for the translation plan.
  """

  alias GlossiaAgent.Config.LLMConfig.AgentConfig
  alias GlossiaAgent.Config.Parser.Entry

  defmodule OutputPlan do
    @moduledoc false
    defstruct [:lang, :output_path]

    @type t :: %__MODULE__{
            lang: String.t(),
            output_path: String.t()
          }
  end

  defmodule SourcePlan do
    @moduledoc false
    defstruct [
      :source_path,
      :abs_path,
      :base_path,
      :rel_path,
      :format,
      :kind,
      :entry,
      :context_bodies,
      :context_paths,
      :translator,
      :outputs
    ]

    @type t :: %__MODULE__{
            source_path: String.t(),
            abs_path: String.t(),
            base_path: String.t(),
            rel_path: String.t(),
            format: GlossiaAgent.Format.t(),
            kind: :translate | :revisit,
            entry: Entry.t(),
            context_bodies: [String.t()],
            context_paths: [String.t()],
            translator: AgentConfig.t(),
            outputs: [OutputPlan.t()]
          }
  end

  defmodule Plan do
    @moduledoc false
    defstruct [:root, :content_files, :sources]

    @type t :: %__MODULE__{
            root: String.t(),
            content_files: [GlossiaAgent.Config.Parser.ContentFile.t()],
            sources: [SourcePlan.t()]
          }
  end

  @doc "Get the language key for an output plan entry."
  @spec output_lang_key(OutputPlan.t()) :: String.t()
  def output_lang_key(%OutputPlan{lang: lang}) do
    trimmed = String.trim(lang)
    if trimmed == "", do: "_", else: trimmed
  end
end
