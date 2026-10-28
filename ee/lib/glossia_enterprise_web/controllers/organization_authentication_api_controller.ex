defmodule GlossiaEnterpriseWeb.OrganizationAuthenticationApiController do
  use GlossiaWeb, :controller
  alias Glossia.{Accounts, ChangesetErrors, Organizations}
  alias GlossiaWeb.ApiAuthorization
  alias GlossiaEnterprise.OrganizationAuthentication, as: Authentication

  def show(conn, params), do: respond(conn, params, :show)
  def update(conn, params), do: respond(conn, params, :update)
  def verify(conn, params), do: respond(conn, params, :verify)

  defp respond(conn, %{"handle" => handle} = params, action) do
    account = Accounts.get_account_by_handle(handle)
    organization = account && Organizations.get_organization_for_account(account)

    if organization do
      case ApiAuthorization.authorize(conn, :organization_admin, account) do
        {:ok, conn} ->
          user = conn.assigns.current_user

          result =
            case action do
              :show ->
                Authentication.configuration(organization, user)

              :update ->
                Authentication.configure(organization, user, params)

              :verify ->
                with {:ok, verified} <- Authentication.verify(organization, user),
                     do: Authentication.configuration(verified, user)
            end

          case result do
            {:ok, configuration} ->
              json(conn, configuration)

            {:error, %Ecto.Changeset{} = changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{errors: ChangesetErrors.to_map(changeset)})

            {:error, reason} ->
              conn |> put_status(:unprocessable_entity) |> json(%{error: reason})
          end

        {:error, conn} ->
          conn
      end
    else
      conn |> put_status(:not_found) |> json(%{error: "Organization not found"})
    end
  end
end
