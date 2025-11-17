defmodule GlossiaWeb.Schemas.TranslationRequest do
  @moduledoc """
  Schema for translation API request.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Translation Request",
    description: "Request body for translating content in any supported format",
    type: :object,
    properties: %{
      content: %Schema{
        type: :string,
        description: """
        The content to translate. Can be plain text or structured file content.
        For structured formats (JSON, YAML, etc.), send the raw file content as a string.
        """,
        example: "Hello, world!"
      },
      format: %Schema{
        type: :string,
        description: """
        Format of the content. Determines how the content is parsed and translated.
        Defaults to 'text' if not specified.

        Currently supported formats:
        - text: Plain text translation
        - json: JSON files (preserves formatting and structure)
        """,
        enum: ["text", "json"],
        default: "text",
        example: "text"
      },
      source_locale: %Schema{
        type: :string,
        description: "Source language locale code (e.g., 'en', 'es', 'fr')",
        example: "en"
      },
      target_locale: %Schema{
        type: :string,
        description: "Target language locale code (e.g., 'en', 'es', 'fr')",
        example: "es"
      }
    },
    required: [:content, :source_locale, :target_locale],
    example: %{
      "content" => "Hello, world!",
      "format" => "text",
      "source_locale" => "en",
      "target_locale" => "es"
    }
  })
end
