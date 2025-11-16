defmodule GlossiaWeb.Schemas.TranslationRequest do
  @moduledoc """
  Schema for translation API request.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TranslationRequest",
    description: "Request body for translating text",
    type: :object,
    properties: %{
      text: %Schema{
        type: :string,
        description: "The text to translate",
        example: "Hello, world!"
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
    required: [:text, :source_locale, :target_locale],
    example: %{
      "text" => "Hello, world!",
      "source_locale" => "en",
      "target_locale" => "es"
    }
  })
end
