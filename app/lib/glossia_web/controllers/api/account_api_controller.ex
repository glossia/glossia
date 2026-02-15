defmodule GlossiaWeb.Api.AccountApiController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias GlossiaWeb.Api.Serialization
  alias GlossiaWeb.ApiAuthorization

  def index(conn, params) do
    case ApiAuthorization.authorize(conn, :account_read) do
      {:ok, conn} ->
        user = conn.assigns[:current_user]

        case Accounts.list_user_accounts(user, params) do
          {:ok, {accounts, meta}} ->
            json(conn, %{
              accounts:
                Enum.map(accounts, fn account ->
                  %{
                    handle: account.handle,
                    type: account.type,
                    visibility: account.visibility
                  }
                end),
              meta: Serialization.meta(meta)
            })

          {:error, meta} ->
            conn
            |> put_status(:bad_request)
            |> json(%{errors: meta.errors})
        end

      {:error, conn} ->
        conn
    end
  end
end
