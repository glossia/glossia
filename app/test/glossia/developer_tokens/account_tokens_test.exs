defmodule Glossia.DeveloperTokens.AccountTokensTest do
  use Glossia.DataCase, async: true

  alias Glossia.DeveloperTokens
  alias GlossiaWeb.ApiTestHelpers

  test "get_account_token_by_value/1 preloads user account" do
    user = ApiTestHelpers.create_user("token-user@test.com", "token-user")

    {:ok, %{plain_token: plain_token}} =
      DeveloperTokens.create_account_token(user.account, user, %{"name" => "Test token"})

    assert {:ok, token} = DeveloperTokens.get_account_token_by_value(plain_token)
    assert token.user.id == user.id
    assert token.user.account.id == user.account.id
    assert token.user.account.handle == user.account.handle
  end
end
