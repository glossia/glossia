defmodule Glossia.AccountTokensTest do
  use Glossia.DataCase, async: true

  alias Glossia.AccountTokens
  alias Glossia.TestHelpers

  test "get_account_token_by_value/1 preloads user account" do
    user = TestHelpers.create_user("token-user@test.com", "token-user")

    {:ok, %{plain_token: plain_token}} =
      AccountTokens.create_account_token(user.account, user, %{"name" => "Test token"})

    assert {:ok, token} = AccountTokens.get_account_token_by_value(plain_token)
    assert token.user.id == user.id
    assert token.user.account.id == user.account.id
    assert token.user.account.handle == user.account.handle
  end

  test "create_account_token/4 stores hashed token and emits an event" do
    user = TestHelpers.create_user("create-token@test.com", "create-token")

    assert {:ok, %{token: token, plain_token: plain_token}} =
             TestHelpers.expect_event(
               "token.created",
               fn ->
                 AccountTokens.create_account_token(user.account, user, %{"name" => "CLI token"},
                   via: :api
                 )
               end,
               %{
                 :account_id => user.account.id,
                 :user_id => user.id,
                 {:opt, :via} => :api,
                 {:opt, :resource_type} => "account_token"
               }
             )

    assert String.starts_with?(plain_token, "glsa_")
    assert token.token_hash != plain_token
    assert token.token_prefix == String.slice(plain_token, 0, 12)
  end

  test "update_account_token/3 updates the token and emits an event" do
    user = TestHelpers.create_user("update-token@test.com", "update-token")

    {:ok, %{token: token}} =
      AccountTokens.create_account_token(user.account, user, %{"name" => "Old token"})

    assert {:ok, updated_token} =
             TestHelpers.expect_event(
               "token.updated",
               fn ->
                 AccountTokens.update_account_token(token, %{"name" => "New token"},
                   actor: user,
                   via: :dashboard
                 )
               end,
               %{
                 :account_id => user.account.id,
                 :user_id => user.id,
                 {:opt, :via} => :dashboard,
                 {:opt, :resource_type} => "account_token"
               }
             )

    assert updated_token.name == "New token"
  end

  test "revoke_account_token/3 revokes the token and emits an event" do
    user = TestHelpers.create_user("revoke-token@test.com", "revoke-token")

    {:ok, %{token: token}} =
      AccountTokens.create_account_token(user.account, user, %{"name" => "Revokable token"})

    assert {:ok, revoked_token} =
             TestHelpers.expect_event(
               "token.revoked",
               fn ->
                 AccountTokens.revoke_account_token(token.id, user.account.id,
                   actor: user,
                   via: :mcp
                 )
               end,
               %{
                 :account_id => user.account.id,
                 :user_id => user.id,
                 {:opt, :via} => :mcp,
                 {:opt, :resource_type} => "account_token"
               }
             )

    assert revoked_token.revoked_at
  end

  test "create_oauth_application/4 persists the app and emits an event" do
    user = TestHelpers.create_user("oauth-app@test.com", "oauth-app")

    attrs = %{
      "name" => "Companion app",
      "redirect_uris" => "https://example.com/callback"
    }

    assert {:ok, %{app: app, client_id: client_id, client_secret: client_secret}} =
             TestHelpers.expect_event(
               "oauth_app.created",
               fn ->
                 AccountTokens.create_oauth_application(user.account, user, attrs, via: :api)
               end,
               %{
                 :account_id => user.account.id,
                 :user_id => user.id,
                 {:opt, :via} => :api,
                 {:opt, :resource_type} => "oauth_application"
               }
             )

    assert app.name == "Companion app"
    assert client_id
    assert client_secret
  end
end
