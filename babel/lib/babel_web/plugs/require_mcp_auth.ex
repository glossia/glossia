defmodule BabelWeb.Plugs.RequireMcpAuth do
  @moduledoc false

  import Plug.Conn

  alias Babel.Accounts.Account
  alias BabelWeb.MCPAuthorization

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_account] do
      %Account{} -> conn
      _ -> unauthorized(conn)
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header("www-authenticate", MCPAuthorization.www_authenticate())
    |> send_resp(:unauthorized, JSON.encode!(%{error: "unauthorized"}))
    |> halt()
  end
end
