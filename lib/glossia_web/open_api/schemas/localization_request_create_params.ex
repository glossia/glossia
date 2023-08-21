defmodule GlossiaWeb.OpenAPI.Schemas.LocalizationRequestCreateParams do
  # Modules
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Localization request create params",
    description: "The parameters used to create a new localization request.",
    type: :object,
    properties: %{
      id: %Schema{
        type: :string,
        description:
          "A string that uniquely identifies the localization request in time. For example, for content hosted in Git repositories, that's the commit SHA."
      },
      modules: %Schema{
        type: :array,
        description: "Modules of localizable content to be localized"
      }

      # name: %Schema{type: :string, description: "User name", pattern: ~r/[a-zA-Z][a-zA-Z0-9_]+/},
      # email: %Schema{type: :string, description: "Email address", format: :email},
      # birthday: %Schema{type: :string, description: "Birth date", format: :date},
      # inserted_at: %Schema{
      #   type: :string,
      #   description: "Creation timestamp",
      #   format: :"date-time"
      # },
      # updated_at: %Schema{type: :string, description: "Update timestamp", format: :"date-time"}
    },
    required: [:id, :modules],
    example: %{
      "id" => 123,
      "modules" => [%{}]
    }
  })
end
