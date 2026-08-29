defmodule GlossiaWeb.Plugs.InternalBabelAuth do
  @moduledoc false

  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn

  alias Glossia.BabelWorkloadIdentity

  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, token} <- bearer_token(conn),
         {:ok, principal} <- BabelWorkloadIdentity.verify(token) do
      assign(conn, :babel_principal, principal)
    else
      {:error, :not_configured} -> unavailable(conn)
      {:error, :invalid_jwks} -> unavailable(conn)
      {:error, _reason} -> unauthorized(conn)
    end
  end

  defp bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] when token != "" -> {:ok, token}
      ["bearer " <> token] when token != "" -> {:ok, token}
      _ -> {:error, :missing_bearer_token}
    end
  end

  defp unavailable(conn) do
    Logger.error("Babel workload identity verification is not configured")

    conn
    |> put_status(:service_unavailable)
    |> json(%{error: "workload_identity_unavailable"})
    |> halt()
  end

  defp unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "invalid_workload_identity"})
    |> halt()
  end
end
