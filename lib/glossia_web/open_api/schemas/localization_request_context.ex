defmodule GlossiaWeb.OpenAPI.Schemas.LocalizationRequestContext do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Localization request context",
    description: "The context of a localizable content.",
    type: :object,
    properties: %{},
    required: []
  })
end
