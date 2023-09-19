defmodule Glossia.Foundation.API.Web.Controllers.Project.LocalizationRequestController do
  # Modules
  use Glossia.Foundation.Application.Web.Helpers.App, :controller
  use OpenApiSpex.ControllerSpecs
  alias Glossia.Localizations

  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true

  tags ["localization-requests"]

  alias Glossia.Foundation.Localizations.Core, as: Localizations
  alias Glossia.Foundation.API.Core.Schemas.LocalizationRequest.CreateResponse
  alias Glossia.Foundation.Localizations.Core.API.Schemas.LocalizationRequest

  operation :create,
    summary: "Creates a new localization request",
    parameters: [],
    request_body: {"Localization request params", "application/json", LocalizationRequest},
    responses: [
      ok: {"Localization request response", "application/json", CreateResponse}
    ]

  @spec create(conn :: Plug.Conn.t(), any) :: Plug.Conn.t()
  @dialyzer {:nowarn_function, create: 2}
  def create(conn, _params) do
    %{body_params: %LocalizationRequest{} = request} = conn
    Glossia.Foundation.Accounts.Web.Policies.enforce!(conn, {:create, :localization_request})

    result =
      Localizations.process_localization_request(request, %{
        project_id: conn.assigns[:authenticated_project].id
      })

    case result do
      :ok -> conn |> put_status(:ok) |> json(%CreateResponse{})
      {:error, _error} -> conn |> put_status(:internal_server_error) |> json(%CreateResponse{})
    end
  end
end
