defmodule GlossiaWeb.Api.TokenApiController do
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
            case DeveloperTokens.list_account_tokens(account, params) do
              {:ok, {tokens, meta}} ->
                conn
                |> json(%{
                  tokens: Enum.map(tokens, &serialize_token/1),
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

            attrs = %{
              "name" => params["name"],
              "description" => params["description"],
              "scope" => params["scope"] || "",
              "expires_at" => parse_expires_at(params["expires_in_days"])
            }

            case DeveloperTokens.create_account_token(account, user, attrs, via: :api) do
              {:ok, %{token: token, plain_token: plain_token}} ->
                conn
                |> put_status(:created)
                |> json(%{
                  token: serialize_token(token),
                  plain_token: plain_token
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

  def revoke(conn, %{"handle" => handle, "id" => id}) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :api_credentials_write, account) do
          {:ok, conn} ->
            user = conn.assigns[:current_user]

            case DeveloperTokens.revoke_account_token(id, account.id, actor: user, via: :api) do
              {:ok, _token} ->
                conn |> json(%{status: "revoked"})

              {:error, :not_found} ->
                conn |> put_status(:not_found) |> json(%{error: "token not found"})
            end

          {:error, conn} ->
            conn
        end
    end
  end

  defp parse_expires_at(nil), do: nil
  defp parse_expires_at(""), do: nil

  defp parse_expires_at(days_str) when is_binary(days_str) do
    case Integer.parse(days_str) do
      {days, ""} when days > 0 -> DateTime.add(DateTime.utc_now(), days, :day)
      _ -> nil
    end
  end

  defp parse_expires_at(_), do: nil

  defp serialize_token(token) do
    %{
      id: token.id,
      name: token.name,
      description: token.description,
      token_prefix: token.token_prefix,
      scope: token.scope,
      expires_at: token.expires_at,
      last_used_at: token.last_used_at,
      inserted_at: token.inserted_at
    }
  end
end
