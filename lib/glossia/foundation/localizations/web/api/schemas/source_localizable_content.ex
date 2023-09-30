defmodule Glossia.Foundation.Localizations.Web.API.Schemas.SourceLocalizableContent do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias Glossia.Foundation.Localizations.Web.API.Schemas.SourceContext
  alias Glossia.Foundation.Localizations.Web.API.Schemas.Checksum

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
