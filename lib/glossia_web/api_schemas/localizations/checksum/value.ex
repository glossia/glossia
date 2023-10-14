defmodule GlossiaWeb.APISchemas.Localizations.Checksum.Value do
  @moduledoc false
  alias OpenApiSpex.Schema
  require OpenApiSpex

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
