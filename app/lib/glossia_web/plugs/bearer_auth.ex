defmodule GlossiaWeb.Plugs.BearerAuth do
  @moduledoc """
  Extracts Bearer token from the Authorization header, validates it via
  Boruta, and assigns `current_user` and `scopes` to conn.

  When a token is present but invalid (expired, revoked, unknown), the
  request is rejected with 401. When no token is present, the request
  continues unauthenticated (downstream plugs like RequireAuth handle that).
  """
  import Plug.Conn

  alias Glossia.Accounts
  alias Glossia.DeveloperTokens

  def init(opts), do: opts

  def call(conn, _opts) do
    case extract_bearer_token(conn) do
      {:error, :no_token} ->
        assign_unauthenticated(conn)

      {:ok, token_value} ->
        validate_token(conn, token_value)
    end
  end

  defp validate_token(conn, token_value) do
    case validate_boruta_token(token_value) do
      {:ok, user, scopes} ->
        conn
        |> assign(:current_user, user)
        |> assign(:scopes, scopes)

      :error ->
        validate_account_token(conn, token_value)
    end
  end

  defp validate_boruta_token(token_value) do
    with token when not is_nil(token) <- get_token(token_value),
         false <- revoked?(token),
         false <- expired?(token),
         user when not is_nil(user) <- Accounts.get_user(token.sub) do
      {:ok, user, parse_scopes(token.scope)}
    else
      _ -> :error
    end
  end

  defp validate_account_token(conn, "glsa_" <> _ = token_value) do
    case DeveloperTokens.get_account_token_by_value(token_value) do
      {:ok, token} ->
        conn
        |> assign(:current_user, token.user)
        |> assign(:scopes, parse_scopes(token.scope))

      _ ->
        reject_unauthorized(conn)
    end
  end

  defp validate_account_token(conn, _token_value) do
    reject_unauthorized(conn)
  end

  defp extract_bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, String.trim(token)}
      _ -> {:error, :no_token}
    end
  end

  defp get_token(value) do
    Boruta.Config.access_tokens().get_by(value: value)
  end

  defp revoked?(%{revoked_at: nil}), do: false
  defp revoked?(%{revoked_at: _}), do: true
  defp revoked?(_), do: true

  defp expired?(%{expires_at: expires_at}) when is_integer(expires_at) do
    DateTime.utc_now() |> DateTime.to_unix() >= expires_at
  end

  defp expired?(%{expires_at: %DateTime{} = expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :lt
  end

  defp expired?(_), do: true

  defp reject_unauthorized(conn) do
    conn
    |> put_resp_header("www-authenticate", "Bearer")
    |> send_resp(401, JSON.encode!(%{error: "invalid_token"}))
    |> halt()
  end

  defp assign_unauthenticated(conn) do
    conn
    |> assign(:current_user, nil)
    |> assign(:scopes, [])
  end

  defp parse_scopes(nil), do: []
  defp parse_scopes(""), do: []
  defp parse_scopes(scope) when is_binary(scope), do: String.split(scope, " ")
  defp parse_scopes(_), do: []
end
