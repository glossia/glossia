defmodule Glossia.Modules.API.Web.Controllers.Project.LocalizationRequestController do
  # Modules
  use GlossiaWeb, :controller
  use OpenApiSpex.ControllerSpecs
  alias Glossia.Localizations

  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true

  tags ["localization-requests"]

  alias Glossia.Projects.Project
  alias Glossia.Modules.Localizations
  alias Glossia.Modules.API.Core.Schemas.LocalizationRequest.CreateResponse
  alias Glossia.Modules.Localizations.Core.API.Schemas.LocalizationRequest

  operation :create,
    summary: "Creates a new localization request",
    parameters: [],
    request_body: {"Localization request params", "application/json", LocalizationRequest},
    responses: [
      ok: {"Localization request response", "application/json", CreateResponse}
    ]

  @spec create(conn :: %{body_params: LocalizationRequest.t(), assigns: %{ current_project: Project.t() }}, params :: map()) :: Plug.Conn.t()
  def create(conn = %{body_params: %LocalizationRequest{} = request}, _params) do
    # GlossiaWeb.Auth.Policies.enforce!(conn, {:create, :localization_request})
    result = Localizations.process_localization_request(request, %{
      project: conn.assigns[:current_project]
    })
    case result do
      :ok -> conn |> put_status(:ok) |> json(%CreateResponse{})
      {:error, _error} -> conn |> put_status(:internal_server_error) |> json(%CreateResponse{})
    end
  end
end
