defmodule Glossia.Foundation.Localizations.Web.API.Schemas.Checksum.Value do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema

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
