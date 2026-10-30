defmodule GlossiaWeb.PomeriumAccessController do
  @moduledoc false

  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.Pomerium
  alias Glossia.TemporaryAccess

  def create(conn, %{"account" => handle}) do
    with [assertion] <- get_req_header(conn, "x-pomerium-jwt-assertion"),
         {:ok, identity} <- Pomerium.identity_from_assertion(assertion),
         user when not is_nil(user) <- Accounts.get_user_by_email(identity.email),
         account when not is_nil(account) <- Accounts.get_account_by_handle(handle),
         {:ok, grant} <- TemporaryAccess.authorize_pomerium_access(user, account, identity) do
      conn
      |> put_session(:pomerium_access, %{"user_id" => user.id, "grant_id" => grant.id})
      |> GlossiaWeb.BrowserAuthentication.sign_in(user, ~p"/#{account.handle}")
    else
      _error ->
        conn
        |> put_status(:not_found)
        |> put_view(GlossiaWeb.ErrorHTML)
        |> put_root_layout(false)
        |> put_layout(false)
        |> render(:"404")
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:not_found)
    |> put_view(GlossiaWeb.ErrorHTML)
    |> put_root_layout(false)
    |> put_layout(false)
    |> render(:"404")
  end
end
