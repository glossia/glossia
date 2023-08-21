defmodule GlossiaWeb.OpenAPI.Schemas.LocalizationRequest.Context do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Localization request context",
    description: "The context of a localizable content.",
    type: :object,
    properties: %{
      language: %Schema{type: :string, description: "The language of the content"},
      country: %Schema{type: :string, description: "The country of the content"}
    },
    required: []
  })
end
