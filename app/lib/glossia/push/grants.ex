defmodule Glossia.Push.Grants do
  @moduledoc false
  import Ecto.Query
  alias Boruta.Ecto.{Client, Token}
  alias Glossia.Repo

  @native_callback "glossia://oauth/callback"

  # The native Rust app dynamically registers a public PKCE client per install.
  # The legacy shared Expo client is deliberately NOT an installation identity.
  def native_client?(%Client{
        confidential: false,
        pkce: true,
        public_refresh_token: true,
        public_revoke: true,
        token_endpoint_auth_methods: [],
        redirect_uris: [@native_callback]
      }),
      do: true

  def native_client?(_), do: false

  def client_for_token(%{kind: :oauth_access_token, id: id}, user_id) do
    case Repo.get(Token, id, log: false) do
      %Token{type: "access_token", sub: ^user_id, revoked_at: nil, expires_at: expires_at} = token
      when expires_at > 0 ->
        client = Repo.get(Client, token.client_id, log: false)

        if expires_at > System.system_time(:second) and native_client?(client) and
             active?(user_id, client.id),
           do: {:ok, client.id},
           else: {:error, :native_client_required}

      _ ->
        {:error, :native_client_required}
    end
  end

  def client_for_token(_, _), do: {:error, :native_client_required}

  def active?(user_id, client_id), do: scopes(user_id, client_id) != []

  # Refresh rotation consumes the previous refresh token. Access-token expiry is
  # not session expiry: a valid refresh grant keeps background delivery enabled.
  # Read the persisted grant, not Boruta's adapter cache, on every send.
  def scopes(user_id, client_id) do
    from(t in Token,
      join: c in Client,
      on: c.id == t.client_id,
      where: c.confidential == false and c.pkce == true and c.public_refresh_token == true,
      where: c.public_revoke == true and c.token_endpoint_auth_methods == ^[],
      where: c.redirect_uris == ^[@native_callback],
      where: t.sub == ^user_id and t.client_id == ^client_id and t.type == "access_token",
      where: not is_nil(t.refresh_token) and is_nil(t.revoked_at),
      where: is_nil(t.refresh_token_revoked_at),
      where:
        fragment(
          "? + (? * interval '1 second') > (statement_timestamp() AT TIME ZONE 'UTC')",
          t.inserted_at,
          c.refresh_token_ttl
        ),
      order_by: [desc: t.inserted_at, desc: t.id],
      limit: 10,
      select: t.scope
    )
    |> Repo.all(log: false)
    |> Enum.map(&String.split(&1 || "", " ", trim: true))
  end
end
