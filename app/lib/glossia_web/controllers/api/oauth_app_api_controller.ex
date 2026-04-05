defmodule GlossiaWeb.Api.OAuthAppApiController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.DeveloperTokens
  alias GlossiaWeb.Api.Serialization
  alias GlossiaWeb.ApiAuthorization

  def index(conn, %{"handle" => handle} = params) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :api_credentials_read, account) do
          {:ok, conn} ->
            case DeveloperTokens.list_oauth_applications(account, params) do
              {:ok, {apps, meta}} ->
                conn
                |> json(%{
                  oauth_applications: Enum.map(apps, &serialize_app/1),
                  meta: Serialization.meta(meta)
                })

              {:error, meta} ->
                conn |> put_status(:bad_request) |> json(%{errors: meta.errors})
            end

          {:error, conn} ->
            conn
        end
    end
  end

  def create(conn, %{"handle" => handle} = params) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :api_credentials_write, account) do
          {:ok, conn} ->
            user = conn.assigns[:current_user]

            case DeveloperTokens.create_oauth_application(account, user, params, via: :api) do
              {:ok, %{app: app, client_id: client_id, client_secret: client_secret}} ->
                conn
                |> put_status(:created)
                |> json(%{
                  oauth_application: serialize_app(app),
                  client_id: client_id,
                  client_secret: client_secret
                })

              {:error, changeset} ->
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{errors: Glossia.ChangesetErrors.to_map(changeset)})
            end

          {:error, conn} ->
            conn
        end
    end
  end

  def show(conn, %{"handle" => handle, "id" => id}) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :api_credentials_read, account) do
          {:ok, conn} ->
            app = DeveloperTokens.get_oauth_application!(id, account.id)
            client = DeveloperTokens.get_boruta_client_for_app(app)

            conn
            |> json(%{
              oauth_application:
                Map.merge(serialize_app(app), %{
                  client_id: client.id,
                  redirect_uris: client.redirect_uris
                })
            })

          {:error, conn} ->
            conn
        end
    end
  end

  def update(conn, %{"handle" => handle, "id" => id} = params) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :api_credentials_write, account) do
          {:ok, conn} ->
            user = conn.assigns[:current_user]
            app = DeveloperTokens.get_oauth_application!(id, account.id)

            case DeveloperTokens.update_oauth_application(app, params, actor: user, via: :api) do
              {:ok, updated_app} ->
                conn |> json(%{oauth_application: serialize_app(updated_app)})

              {:error, changeset} ->
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{errors: Glossia.ChangesetErrors.to_map(changeset)})
            end

          {:error, conn} ->
            conn
        end
    end
  end

  def delete(conn, %{"handle" => handle, "id" => id}) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :api_credentials_write, account) do
          {:ok, conn} ->
            user = conn.assigns[:current_user]
            app = DeveloperTokens.get_oauth_application!(id, account.id)

            case DeveloperTokens.delete_oauth_application(app, actor: user, via: :api) do
              :ok ->
                conn |> json(%{status: "deleted"})

              {:error, _} ->
                conn
                |> put_status(:internal_server_error)
                |> json(%{error: "could not delete application"})
            end

          {:error, conn} ->
            conn
        end
    end
  end

  def regenerate_secret(conn, %{"handle" => handle, "id" => id}) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :api_credentials_write, account) do
          {:ok, conn} ->
            user = conn.assigns[:current_user]
            app = DeveloperTokens.get_oauth_application!(id, account.id)

            case DeveloperTokens.regenerate_oauth_application_secret(app, actor: user, via: :api) do
              {:ok, %{client_secret: secret}} ->
                conn |> json(%{client_secret: secret})

              {:error, _} ->
                conn
                |> put_status(:internal_server_error)
                |> json(%{error: "could not regenerate secret"})
            end

          {:error, conn} ->
            conn
        end
    end
  end

  defp serialize_app(app) do
    %{
      id: app.id,
      name: app.name,
      description: app.description,
      homepage_url: app.homepage_url,
      inserted_at: app.inserted_at
    }
  end
end
