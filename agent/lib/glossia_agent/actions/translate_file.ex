defmodule GlossiaAgent.Actions.TranslateFile do
  @moduledoc """
  Jido Action: Translate a single source file to a target language.

  Reads the source content, calls the LLM translation engine with
  validation, and returns the translated text.
  """

  use Jido.Action,
    name: "translate_file",
    description: "Translate a single file to a target language via LLM",
    schema: [
      source_content: [type: :string, required: true, doc: "Source file content"],
      target_lang: [type: :string, required: true, doc: "Target language code"],
      format: [type: :atom, required: true, doc: "File format (e.g. :markdown, :json)"],
      context: [type: :string, default: "", doc: "Additional context for translation"],
      preserve: [type: {:list, :string}, default: [], doc: "Elements to preserve"],
      frontmatter: [type: :string, default: "preserve", doc: "Frontmatter handling mode"],
      translator: [type: :any, required: true, doc: "LLM translator agent config"]
    ]

  @spec run(map(), map()) :: {:ok, map()} | {:error, term()}
  def run(params, _context) do
    result =
      GlossiaAgent.TranslateEngine.translate_file(%{
        source: params.source_content,
        target_lang: params.target_lang,
        format: params.format,
        context: params.context,
        preserve: params.preserve,
        frontmatter: params.frontmatter,
        translator: params.translator
      })

    {:ok, %{translated_text: result.text, usage: result.usage}}
  end
end
