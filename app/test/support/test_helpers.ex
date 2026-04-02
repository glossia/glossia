defmodule Glossia.TestHelpers do
  @moduledoc false

  import Plug.Conn, only: [put_req_header: 3]

  alias Glossia.Accounts.{Account, User}
  alias Glossia.Repo

  def create_user(email, handle_prefix, opts \\ []) do
    has_access = Keyword.get(opts, :has_access, true)

    {:ok, account} =
      %Account{}
      |> Account.changeset(%{
        handle: "#{handle_prefix}-#{System.unique_integer([:positive])}",
        type: "user",
        has_access: has_access
      })
      |> Repo.insert()

    {:ok, user} =
      %User{account_id: account.id}
      |> User.changeset(%{email: email, has_access: has_access})
      |> Repo.insert()

    %{user | account: account}
  end

  def authenticate(conn, user, scopes) when is_list(scopes) do
    # Use Boruta's client changeset to properly create a client with required keys.
    {:ok, client} =
      Boruta.Ecto.Client.create_changeset(%Boruta.Ecto.Client{}, %{
        name: "test-client-#{System.unique_integer([:positive])}",
        redirect_uris: ["http://localhost"],
        access_token_ttl: 3600,
        authorization_code_ttl: 60
      })
      |> Repo.insert()

    # Use Boruta's token changeset to create a valid access token.
    {:ok, token} =
      Boruta.Ecto.Token.changeset(%Boruta.Ecto.Token{}, %{
        client_id: client.id,
        sub: to_string(user.id),
        scope: Enum.join(scopes, " "),
        access_token_ttl: 3600
      })
      |> Repo.insert()

    conn
    |> put_req_header("authorization", "Bearer #{token.value}")
    |> put_req_header("content-type", "application/json")
  end
end
