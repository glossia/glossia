defmodule Glossia.Foundation.Localizations.Web.API.Schemas.Checksum do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias Glossia.Foundation.Localizations.Web.API.Schemas.Checksum.Value, as: ChecksumValue

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
      content: ChecksumValue,
      cache: ChecksumValue
    },
    required: [:cache_id]
  })
end
