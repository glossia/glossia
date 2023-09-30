defmodule Glossia.Foundation.Localizations.Web.API.Controllers.LocalizationController do
  # Modules
  use Glossia.Foundation.Application.Web.Helpers.App, :controller
  use OpenApiSpex.ControllerSpecs
  alias Glossia.Localizations

  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true

  tags ["localizations"]

  alias Glossia.Foundation.Localizations.Core, as: Localizations
  alias Glossia.Foundation.Localizations.Web.API.Schemas.CreateResponse
  alias Glossia.Foundation.Localizations.Web.API.Schemas.Localization

  operation :create,
    summary: "Creates a new localization",
    parameters: [],
    request_body: {"Localization params", "application/json", Localization},
    responses: [
      ok: {"Localization response", "application/json", CreateResponse}
    ]

  @spec create(conn :: Plug.Conn.t(), any) :: Plug.Conn.t()
  @dialyzer {:nowarn_function, create: 2}
  def create(conn, _params) do
    %{body_params: %Localization{} = localization} = conn
    Glossia.Foundation.Accounts.Web.Policies.enforce!(conn, {:create, :localization_request})

    result =
      Localizations.process_localization(localization, %{
        project_id: conn.assigns[:authenticated_project].id
      })

    case result do
      :ok -> conn |> put_status(:ok) |> json(%CreateResponse{})
      {:error, _error} -> conn |> put_status(:internal_server_error) |> json(%CreateResponse{})
    end
  end
end
