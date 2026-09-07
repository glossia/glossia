defmodule GlossiaWeb.AuthenticatedRouterController do
  use GlossiaWeb, :controller

  def show(conn, %{"path" => path}) do
    case Glossia.Extensions.authenticated_router().resolve(conn, path) do
      %Plug.Conn{} = conn -> conn
      :not_found -> raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
    end
  end
end
