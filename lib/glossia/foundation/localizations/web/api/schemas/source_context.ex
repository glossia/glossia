defmodule Glossia.Foundation.Localizations.Web.API.Schemas.SourceContext do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Localization request source context",
    description: "The context of a source localizable content.",
    type: :object,
    properties: %{
      language: %Schema{type: :string, description: "The language of the content"},
      country: %Schema{type: :string, description: "The country of the content"}
    },
    required: [:language]
  })
end
