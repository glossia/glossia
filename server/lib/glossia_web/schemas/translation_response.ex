defmodule GlossiaWeb.Schemas.TranslationResponse do
  @moduledoc """
  Schema for translation API response.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TranslationResponse",
    description: "Successful translation response",
    type: :object,
    properties: %{
      translated_text: %Schema{
        type: :string,
        description: "The translated text",
        example: "¡Hola, mundo!"
      },
      source_locale: %Schema{
        type: :string,
        description: "Source language locale code",
        example: "en"
      },
      target_locale: %Schema{
        type: :string,
        description: "Target language locale code",
        example: "es"
      }
    },
    required: [:translated_text, :source_locale, :target_locale],
    example: %{
      "translated_text" => "¡Hola, mundo!",
      "source_locale" => "en",
      "target_locale" => "es"
    }
  })
end
