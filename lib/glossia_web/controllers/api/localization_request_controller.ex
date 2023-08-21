defmodule GlossiaWeb.API.LocalizationRequestController do
  # Modules
  use GlossiaWeb, :controller
  use OpenApiSpex.ControllerSpecs

  tags ["localization-requesets"]

  alias GlossiaWeb.OpenAPI.Schemas.{
    LocalizationRequestCreateResponse,
    LocalizationRequestCreateParams
  }

  operation :create,
    summary: "Creates a new translation request",
    parameters: [
      id: [in: :path, description: "User ID", type: :integer, example: 1001]
    ],
    request_body:
      {"Translation request params", "application/json", LocalizationRequestCreateParams},
    responses: [
      ok: {"Translation request response", "application/json", LocalizationRequestCreateResponse}
    ]

  def create(conn, _params) do
    GlossiaWeb.Auth.Policies.enforce!(conn, {:create, :translation_request})
    json(conn, %{"hello" => "yay"})
  end
end
