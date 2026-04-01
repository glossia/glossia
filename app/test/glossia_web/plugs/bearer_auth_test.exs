defmodule GlossiaWeb.Plugs.BearerAuthTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.DeveloperTokens
  alias Glossia.TestHelpers
  alias GlossiaWeb.Plugs.BearerAuth

  test "authenticates an account token and assigns user + scopes", %{conn: conn} do
    user = TestHelpers.create_user("token-auth@test.com", "token-auth")

    {:ok, %{plain_token: plain_token}} =
      DeveloperTokens.create_account_token(user.account, user, %{
        "name" => "Token",
        "scope" => "voice:read voice:write"
      })

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{plain_token}")
      |> BearerAuth.call([])

    assert conn.assigns.current_user.id == user.id
    assert conn.assigns.current_user.account.handle == user.account.handle
    assert conn.assigns.scopes == ~w(voice:read voice:write)
  end
end
