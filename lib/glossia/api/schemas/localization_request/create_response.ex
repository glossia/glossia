defmodule Glossia.API.Schemas.LocalizationRequest.CreateResponse do
  # Modules
  require OpenApiSpex

  OpenApiSpex.schema(%{
    title: "Localization request create response",
    description: "The response generated when creating a new localization request.",
    type: :object,
    properties:
      %{
        # data: User
      }
  })
end
