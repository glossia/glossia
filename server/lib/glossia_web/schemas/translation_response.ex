defmodule GlossiaWeb.Schemas.TranslationResponse do
  @moduledoc """
  Schema for translation API response.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Translation Response",
    description: "Successful translation response",
    type: :object,
    properties: %{
      content: %Schema{
        type: :string,
        description: "The translated content in the same format as the input",
        example: "¡Hola, mundo!"
      },
      format: %Schema{
        type: :string,
        description: "Format of the content (same as request)",
        example: "text"
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
    required: [:content, :format, :source_locale, :target_locale],
    example: %{
      "content" => "¡Hola, mundo!",
      "format" => "text",
      "source_locale" => "en",
      "target_locale" => "es"
    }
  })
end
