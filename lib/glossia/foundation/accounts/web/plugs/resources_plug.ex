defmodule Glossia.Foundation.Accounts.Web.Plugs.ResourcesPlug do
  @moduledoc """
  This module provides a plug to load authenticated resources to use them
  to authorize requests.
  """

  # Modules
  use PolicyWonk.Resource
  use PolicyWonk.Load

  alias Glossia.Foundation.Accounts.Web.Auth
  alias Glossia.Foundation.Accounts.Core.Repository

  @spec resource(Plug.Conn.t(), :authenticated_project, any) ::
          {:ok, :authenticated_project, nil | Glossia.Foundation.Projects.Core.Models.Project.t()}
  @spec resource(Plug.Conn.t(), :authenticated_user, any) :: {:ok, :authenticated_user, any}
  def resource(conn, :authenticated_user, _) do
    with {user_token, _} when user_token != nil <- get_conn_token(conn),
         {:user, user} when user != nil <-
           {:user, Repository.get_user_by_session_token(user_token)} do
      {:ok, :authenticated_user, user}
    else
      _ ->
        {:ok, :authenticated_user, nil}
    end
  end

  def resource_error(conn, detail) do
    body = %{errors: [%{detail: detail}]} |> Jason.encode!()

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(401, body)
  end

  # Private

  @spec get_conn_token(conn :: Plug.Conn.t()) :: {String.t() | nil, Plug.Conn.t()}
  defp get_conn_token(conn) do
    if token = Plug.Conn.get_session(conn, :user_token) do
      {token, conn}
    else
      conn = Plug.Conn.fetch_cookies(conn, signed: [Auth.remember_me_cookie()])

      if token = conn.cookies[Auth.remember_me_cookie()] do
        {token, Auth.put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end
end
