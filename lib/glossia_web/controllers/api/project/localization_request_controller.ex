defmodule GlossiaWeb.API.Project.LocalizationRequestController do
  # Modules
  use GlossiaWeb, :controller
  use OpenApiSpex.ControllerSpecs
  alias Glossia.Localizations

  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true

  tags ["localization-requests"]

  alias Glossia.API.Schemas.LocalizationRequest.CreateResponse
  alias Glossia.Localizations.API.Schemas.LocalizationRequest

  operation :create,
    summary: "Creates a new localization request",
    parameters: [],
    request_body: {"Localization request params", "application/json", LocalizationRequest},
    responses: [
      ok: {"Localization request response", "application/json", CreateResponse}
    ]
  def create(conn = %{body_params: %LocalizationRequest{} = localization_request}, _params) do
    GlossiaWeb.Auth.Policies.enforce!(conn, {:create, :localization_request})
    Localizations.process_localization_request(request, conn.assigns[:current_project])
    conn |> json(:ok, %CreateResponse{})
  end
end
