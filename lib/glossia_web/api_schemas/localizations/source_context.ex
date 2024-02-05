defmodule GlossiaWeb.APISchemas.Localizations.SourceContext do
  @moduledoc false
  alias OpenApiSpex.Schema
  require OpenApiSpex

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
