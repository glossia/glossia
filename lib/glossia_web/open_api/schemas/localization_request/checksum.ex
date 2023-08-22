defmodule GlossiaWeb.OpenAPI.Schemas.LocalizationRequest.Checksum do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias GlossiaWeb.OpenAPI.Schemas.LocalizationRequest.Checksum.ChecksumValue

  OpenApiSpex.schema(%{
    title: "Localization content checksum",
    description:
      "The checksum of a localizable content for Glossia to determine whether a piece of content should be translated or not.",
    type: :object,
    properties: %{
      cache_id: %Schema{
        type: :string,
        description: "A unique identifier to persist the checksum back to the content source."
      },
      content: %Schema{
        type: :object,
        description: "The checksum of the localizable content",
        properties: %{
          current: ChecksumValue,
          cached: ChecksumValue
        },
        required: [:current]
      },
      context: %Schema{
        type: :object,
        description: "The checksum of the context",
        properties: %{
          current: ChecksumValue,
          cached: ChecksumValue
        },
        required: [:current]
      }
    },
    required: [:cache_id]
  })

  defmodule ChecksumValue do
    OpenApiSpex.schema(%{
      type: :object,
      description: "The checksum of the current localizable content",
      properties: %{
        algorithm: %Schema{
          type: :string,
          description: "The algorithm used to generate the checksum."
        },
        value: %Schema{type: :string, description: "The value of the checksum."}
      },
      required: [:algorithm, :value]
    })
  end
end
