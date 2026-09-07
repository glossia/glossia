defmodule GlossiaWeb.ApiAuthorization do
  @moduledoc false

  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn

  @spec authorize(Plug.Conn.t(), Glossia.Policy.action(), any) ::
          {:ok, Plug.Conn.t()} | {:error, Plug.Conn.t()}
  def authorize(conn, action, object \\ nil) do
    user = conn.assigns[:current_user]
    scopes = conn.assigns[:scopes] || []

    case Glossia.Authz.authorize(action, user, object, scopes: scopes) do
      :ok ->
        {:ok, conn}

      {:error, :insufficient_scope, required_scope} ->
        conn = insufficient_scope(conn, required_scope)
        {:error, conn}

      {:error, :unauthorized} ->
        conn = forbidden(conn)
        {:error, conn}
    end
  end

  defp insufficient_scope(conn, required_scope) do
    conn
    |> put_resp_header(
      "www-authenticate",
      ~s(Bearer error="insufficient_scope", scope="#{required_scope}")
    )
    |> put_status(:forbidden)
    |> json(%{error: "insufficient_scope", required_scope: required_scope})
    |> halt()
  end

  defp forbidden(conn) do
    conn
    |> put_status(:forbidden)
    |> json(%{error: "not_authorized"})
    |> halt()
  end
end
