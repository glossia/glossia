defmodule GlossiaWeb.OpenAPI.Schemas.LocalizationRequestLocalizableContent do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias GlossiaWeb.OpenAPI.Schemas.LocalizationRequestContext

  OpenApiSpex.schema(%{
    title: "Localizable content",
    description: "It represents a unit of localizable content",
    type: :object,
    properties: %{
      id: %Schema{
        type: :string,
        description:
          "An identifier that uniquely identifies the localizable content in the module."
      },
      context: LocalizationRequestContext
    },
    required: [:id]
  })
end
