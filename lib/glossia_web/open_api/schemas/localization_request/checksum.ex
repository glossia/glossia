defmodule GlossiaWeb.OpenAPI.Schemas.LocalizationRequest.Checksum do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Localization content checksum",
    description:
      "The checksum of a localizable content for Glossia to determine whether a piece of content should be translated or not.",
    type: :object,
    properties: %{
      cached: %Schema{
        type: :object,
        description: "The checksum cached from the last localization request",
        properties: %{
          id: %Schema{
            type: :string,
            description: "A unique identifier to persist the checksum back to the content source."
          }
        },
        required: [:id]
      },
      current: %Schema{
        type: :object,
        description: "The checksum of the current content",
        properties: %{
          algorithm: %Schema{
            type: :string,
            description: "The algorithm used to generate the checksum."
          },
          value: %Schema{type: :string, description: "The value of the checksum."}
        },
        required: [:algorithm, :value]
      }
    },
    required: [:cached, :current]
  })
end
