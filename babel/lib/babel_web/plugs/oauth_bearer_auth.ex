defmodule BabelWeb.Plugs.OAuthBearerAuth do
  @moduledoc false

  import Plug.Conn

  alias Babel.Accounts
  alias BabelWeb.MCPAuthorization

  def init(opts), do: opts

  def call(conn, _opts) do
    case extract_bearer_token(conn) do
      :no_token -> assign_unauthenticated(conn)
      {:ok, token_value} -> validate_token(conn, token_value)
    end
  end

  defp validate_token(conn, token_value) do
    with token when not is_nil(token) <- Boruta.Config.access_tokens().get_by(value: token_value),
         false <- revoked?(token),
         false <- expired?(token),
         {:ok, account} <- account_for_sub(token.sub) do
      conn
      |> assign(:current_account, account)
      |> assign(:current_token, token)
      |> assign(:scopes, parse_scopes(token.scope))
    else
      _ -> reject_invalid_token(conn)
    end
  end

  defp extract_bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] when token != "" -> {:ok, String.trim(token)}
      _ -> :no_token
    end
  end

  defp account_for_sub(sub) when is_binary(sub) do
    case Integer.parse(sub) do
      {id, ""} -> account_result(Accounts.get_account(id))
      _ -> :error
    end
  end

  defp account_for_sub(_sub), do: :error

  defp account_result(nil), do: :error
  defp account_result(account), do: {:ok, account}

  defp revoked?(%{revoked_at: nil}), do: false
  defp revoked?(%{revoked_at: _}), do: true
  defp revoked?(_token), do: true

  defp expired?(%{expires_at: expires_at}) when is_integer(expires_at) do
    DateTime.utc_now() |> DateTime.to_unix() >= expires_at
  end

  defp expired?(%{expires_at: %DateTime{} = expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) != :gt
  end

  defp expired?(_token), do: true

  defp parse_scopes(nil), do: []
  defp parse_scopes(""), do: []
  defp parse_scopes(scope) when is_binary(scope), do: String.split(scope, " ", trim: true)
  defp parse_scopes(_scope), do: []

  defp assign_unauthenticated(conn) do
    conn
    |> assign(:current_account, nil)
    |> assign(:current_token, nil)
    |> assign(:scopes, [])
  end

  defp reject_invalid_token(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header(
      "www-authenticate",
      MCPAuthorization.www_authenticate() <> ~s(, error="invalid_token")
    )
    |> send_resp(:unauthorized, JSON.encode!(%{error: "invalid_token"}))
    |> halt()
  end
end
