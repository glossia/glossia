defmodule Glossia.Localizations.API.Schemas.SourceLocalizableContent do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias Glossia.Localizations.API.Schemas.SourceContext
  alias Glossia.Localizations.API.Schemas.Checksum

  OpenApiSpex.schema(%{
    title: "Source localizable content",
    description: "It represents a unit of source localizable content",
    type: :object,
    properties: %{
      id: %Schema{
        type: :string,
        description:
          "An identifier that uniquely identifies the localizable content in the content source."
      },
      context: SourceContext,
      checksum: Checksum
    },
    required: [:id, :context, :checksum]
  })
end
