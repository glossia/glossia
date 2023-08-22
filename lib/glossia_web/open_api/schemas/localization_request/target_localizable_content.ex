defmodule GlossiaWeb.OpenAPI.Schemas.LocalizationRequest.TargetLocalizableContent do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias GlossiaWeb.OpenAPI.Schemas.LocalizationRequest.TargetContext
  alias GlossiaWeb.OpenAPI.Schemas.LocalizationRequest.Checksum

  OpenApiSpex.schema(%{
    title: "Target localizable content",
    description: "It represents a unit of target localizable content",
    type: :object,
    properties: %{
      id: %Schema{
        type: :string,
        description:
          "An identifier that uniquely identifies the localizable content in the content target."
      },
      context: TargetContext,
      checksum: Checksum
    },
    required: [:id, :context, :checksum]
  })
end
