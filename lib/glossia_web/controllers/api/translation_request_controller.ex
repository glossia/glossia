defmodule GlossiaWeb.API.TranslationRequestController do
  # Modules
  use GlossiaWeb, :controller
  use OpenApiSpex.ControllerSpecs

  tags ["translation-requests"]

  alias GlossiaWeb.OpenAPI.Schemas.{
    TranslationRequestCreateResponse,
    TranslationRequestCreateParams
  }

  operation :create,
    summary: "Creates a new translation request",
    parameters: [
      id: [in: :path, description: "User ID", type: :integer, example: 1001]
    ],
    request_body:
      {"Translation request params", "application/json", TranslationRequestCreateParams},
    responses: [
      ok: {"Translation request response", "application/json", TranslationRequestCreateResponse}
    ]

  def create(conn, _params) do
    GlossiaWeb.Auth.Policies.enforce!(conn, {:create, :translation_request})
    json(conn, %{"hello" => "yay"})
  end
end
