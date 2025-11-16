defmodule GlossiaWeb.Schemas.ErrorResponse do
  @moduledoc """
  Schema for error responses.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Error Response",
    description: "Error response",
    type: :object,
    properties: %{
      error: %Schema{
        type: :string,
        description: "Error message",
        example: "Translation failed: API key not configured"
      }
    },
    required: [:error],
    example: %{
      "error" => "Missing required parameters: text, source_locale, target_locale"
    }
  })
end
