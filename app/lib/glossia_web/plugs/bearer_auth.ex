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
  alias Glossia.Accounts.Scope
  alias Glossia.AccountTokens

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
    case verify(token_value) do
      {:ok, user, scopes, token} ->
        conn
        |> assign(:current_scope, Scope.for_user(user))
        |> assign(:current_user, user)
        |> assign(:scopes, scopes)
        |> assign(:current_token, token)

      :error ->
        reject_unauthorized(conn)
    end
  end

  @doc "Validates the current persisted grant and user, for HTTP and persistent native sockets."
  def verify(token_value) when is_binary(token_value) do
    with token when not is_nil(token) <- get_token(token_value),
         false <- revoked?(token),
         false <- expired?(token),
         {:ok, user_id} when not is_nil(user_id) <- Ecto.UUID.cast(token.sub),
         user when not is_nil(user) <- Accounts.get_user(user_id) do
      {:ok, user, parse_scopes(token.scope), %{kind: :oauth_access_token, id: token.id}}
    else
      _ -> verify_account_token(token_value)
    end
  end

  def verify(_), do: :error

  defp verify_account_token("glsa_" <> _ = token_value) do
    case AccountTokens.get_account_token_by_value(token_value) do
      {:ok, token} ->
        {:ok, token.user, parse_scopes(token.scope), %{kind: :account_token, id: token.id}}

      _ ->
        :error
    end
  end

  defp verify_account_token(_token_value), do: :error

  defp extract_bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, String.trim(token)}
      _ -> {:error, :no_token}
    end
  end

  defp get_token(value) do
    # Boruta's adapter caches grants. A long-lived socket must observe scope
    # changes and revocations on other nodes, not a cached authorization. Keep
    # that policy shared with HTTP, and never put the credential in SQL logs.
    Boruta.Config.repo().get_by(Boruta.Ecto.Token, [type: "access_token", value: value],
      log: false
    )
  end

  defp revoked?(%{revoked_at: nil}), do: false
  defp revoked?(%{revoked_at: _}), do: true
  defp revoked?(_), do: true

  defp expired?(%{expires_at: expires_at}) when is_integer(expires_at) do
    DateTime.utc_now() |> DateTime.to_unix() >= expires_at
  end

  defp expired?(%{expires_at: %DateTime{} = expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) != :gt
  end

  defp expired?(_), do: true

  defp reject_unauthorized(conn) do
    key = "auth:invalid_bearer:ip:#{GlossiaWeb.ClientIP.value(conn)}"

    case Glossia.RateLimiter.hit(key, :timer.minutes(1), 30) do
      {:allow, _count} ->
        conn
        |> put_resp_header("www-authenticate", "Bearer")
        |> send_resp(401, JSON.encode!(%{error: "invalid_token"}))
        |> halt()

      {:deny, retry_after_ms} ->
        retry_after = ceil(retry_after_ms / 1_000)

        conn
        |> put_resp_header("retry-after", Integer.to_string(retry_after))
        |> send_resp(429, JSON.encode!(%{error: "too_many_requests"}))
        |> halt()
    end
  end

  defp assign_unauthenticated(conn) do
    conn
    |> assign(:current_scope, nil)
    |> assign(:current_user, nil)
    |> assign(:scopes, [])
    |> assign(:current_token, nil)
  end

  defp parse_scopes(nil), do: []
  defp parse_scopes(""), do: []
  defp parse_scopes(scope) when is_binary(scope), do: String.split(scope, " ")
  defp parse_scopes(_), do: []
end
