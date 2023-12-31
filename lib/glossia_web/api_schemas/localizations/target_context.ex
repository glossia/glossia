defmodule GlossiaWeb.APISchemas.Localizations.TargetContext do
  @moduledoc false
  alias OpenApiSpex.Schema
  require OpenApiSpex

  OpenApiSpex.schema(%{
    title: "Localization request target context",
    description: "The context of a target localizable content.",
    type: :object,
    properties: %{
      language: %Schema{type: :string, description: "The language of the content"},
      country: %Schema{type: :string, description: "The country of the content"}
    },
    required: [:language]
  })
end
