defmodule Glossia.Foundation.Localizations.Core.API.Schemas.Checksum do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias Glossia.Foundation.Localizations.Core.API.Schemas.Checksum.Value, as: ChecksumValue

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
end
