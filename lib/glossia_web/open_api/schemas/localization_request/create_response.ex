defmodule GlossiaWeb.OpenAPI.Schemas.LocalizationRequest.CreateResponse do
  # Modules
  alias OpenApiSpex.Schema
  require OpenApiSpex

  OpenApiSpex.schema(%{
    title: "Localization request create response",
    description: "The response generated when creating a new localization request.",
    type: :object,
    properties:
      %{
        # data: User
      },
    example: %{
      "data" => %{
        "id" => 123,
        "name" => "Joe User",
        "email" => "joe@gmail.com",
        "birthday" => "1970-01-01T12:34:55Z",
        "inserted_at" => "2017-09-12T12:34:55Z",
        "updated_at" => "2017-09-13T10:11:12Z"
      }
    }
  })
end
