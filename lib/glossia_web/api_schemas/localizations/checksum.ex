defmodule GlossiaWeb.APISchemas.Localizations.Checksum do
  @moduledoc false

  alias GlossiaWeb.APISchemas.Localizations.Checksum.Value, as: ChecksumValue
  alias OpenApiSpex.Schema
  require OpenApiSpex

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
