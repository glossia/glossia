defmodule GlossiaAgent.Setup.Prompt do
  @moduledoc """
  Builds the LLM prompt for GLOSSIA.md generation.
  """

  alias GlossiaAgent.Setup.RepoContext

  @doc """
  Build the system prompt for GLOSSIA.md generation.
  """
  @spec system_prompt() :: String.t()
  def system_prompt do
    """
    You are a localization configuration expert. Your task is to analyze a repository \
    and produce a GLOSSIA.md configuration file.

    GLOSSIA.md is Glossia's configuration file. It has two parts:

    1. TOML frontmatter between +++ markers that defines content entries and LLM settings.
    2. Free-text context below the frontmatter that describes the product, tone, and conventions.

    Example GLOSSIA.md:

    +++
    [[content]]
    source = "docs/**/*.md"
    targets = ["es", "fr", "de"]
    output = "docs/i18n/{lang}/{relpath}"
    +++

    This is a developer documentation site.
    Source language: English.
    Tone: technical, concise, friendly.

    Rules for [[content]] entries:
    - `source`: glob pattern matching source files
    - `targets`: array of ISO 639-1 language codes
    - `output`: path template using {lang}, {relpath}, {basename}, {ext}
    - `exclude`: optional array of glob patterns to skip
    - `frontmatter`: optional, "preserve" (default) or "translate" for markdown files

    Output format rules:
    - Use {lang} for the language code in output paths
    - Use {relpath} for the source file's relative path
    - Common pattern: "i18n/{lang}/{relpath}" or "translations/{lang}/{relpath}"

    Respond with ONLY the GLOSSIA.md file content. No explanation, no markdown code fences, \
    no preamble. Start directly with +++ and end with the free-text context.
    """
  end

  @doc """
  Build the user prompt with repository context.
  """
  @spec user_prompt(map(), [String.t()]) :: String.t()
  def user_prompt(context, target_languages \\ []) do
    context_text = RepoContext.format_context(context)

    target_instruction =
      if target_languages != [] do
        targets = Enum.join(target_languages, ", ")
        "Use exactly these target languages: #{targets}."
      else
        "Infer target languages conservatively from the repository. Keep the list minimal (2-3 languages max)."
      end

    """
    Analyze this repository and produce a GLOSSIA.md configuration file.

    #{target_instruction}

    Guidelines:
    - Identify content files that should be translated (markdown docs, JSON/YAML locale files, etc.)
    - Use appropriate glob patterns for source files
    - Choose output path templates that follow the project's existing conventions
    - If the project already has i18n directories, follow that pattern
    - Keep the configuration minimal but complete
    - Add brief free-text context describing the product and tone

    #{context_text}
    """
  end
end
