defmodule GlossiaWeb.API.Project.LocalizationRequestController do
  # Modules
  use GlossiaWeb, :controller
  use OpenApiSpex.ControllerSpecs

  tags ["localization-requests"]

  alias GlossiaWeb.OpenAPI.Schemas.LocalizationRequest.{
    CreateResponse,
    CreateParams
  }

  operation :create,
    summary: "Creates a new localization request",
    parameters: [],
    request_body: {"Localization request params", "application/json", CreateParams},
    responses: [
      ok: {"Localization request response", "application/json", CreateResponse}
    ]

  def create(conn, _params) do
    GlossiaWeb.Auth.Policies.enforce!(conn, {:create, :translation_request})
    json(conn, %{"hello" => "yay"})
  end

  def index(conn, _params) do
    conn |> json(%{"status" => "not-implemented"})
  end
end