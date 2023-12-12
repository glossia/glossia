defmodule GlossiaWeb.APISchemas.Localizations.SourceLocalizableContent do
  @moduledoc false
  alias GlossiaWeb.APISchemas.Localizations.Checksum
  alias GlossiaWeb.APISchemas.Localizations.SourceContext
  alias OpenApiSpex.Schema
  require OpenApiSpex

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
