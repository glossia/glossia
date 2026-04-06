defmodule Glossia.AccountTokensTest do
  use Glossia.DataCase, async: true

  alias Glossia.AccountTokens
  alias Glossia.Accounts.OAuthApplication
  alias Glossia.Repo
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

  test "create_account_token/4 persists scopes" do
    user = TestHelpers.create_user("scoped-token@test.com", "scoped-token")

    assert {:ok, %{token: token}} =
             AccountTokens.create_account_token(user.account, user, %{
               "name" => "Scoped token",
               "scope" => "voice:read voice:write"
             })

    assert token.scope == "voice:read voice:write"
  end

  test "list_account_tokens/2 excludes revoked tokens" do
    user = TestHelpers.create_user("list-token@test.com", "list-token")

    {:ok, %{token: active}} =
      AccountTokens.create_account_token(user.account, user, %{"name" => "Active token"})

    {:ok, %{token: revoked}} =
      AccountTokens.create_account_token(user.account, user, %{"name" => "Revoked token"})

    {:ok, _} = AccountTokens.revoke_account_token(revoked.id, user.account.id)

    assert {:ok, {tokens, _meta}} = AccountTokens.list_account_tokens(user.account)
    assert Enum.map(tokens, & &1.id) == [active.id]
  end

  test "get_account_token!/2 preloads the token user" do
    user = TestHelpers.create_user("get-token@test.com", "get-token")

    {:ok, %{token: token}} =
      AccountTokens.create_account_token(user.account, user, %{"name" => "Loaded token"})

    loaded = AccountTokens.get_account_token!(token.id, user.account.id)

    assert loaded.user.id == user.id
    assert loaded.user.account_id == user.account.id
  end

  test "get_account_token_by_value/1 returns expired for expired tokens" do
    user = TestHelpers.create_user("expired-token@test.com", "expired-token")

    {:ok, %{token: token, plain_token: plain_token}} =
      AccountTokens.create_account_token(user.account, user, %{
        "name" => "Expired token",
        "expires_at" => DateTime.add(DateTime.utc_now(), -3600, :second)
      })

    assert token.expires_at
    assert {:error, :expired} = AccountTokens.get_account_token_by_value(plain_token)
  end

  test "get_account_token_by_value/1 returns invalid for unknown values" do
    assert {:error, :invalid} = AccountTokens.get_account_token_by_value("glsa_unknown")
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

  test "list_oauth_applications/2 returns applications for the account" do
    user = TestHelpers.create_user("list-oauth@test.com", "list-oauth")

    {:ok, %{app: first}} =
      AccountTokens.create_oauth_application(user.account, user, %{
        "name" => "First app",
        "redirect_uris" => "https://example.com/callback"
      })

    {:ok, %{app: second}} =
      AccountTokens.create_oauth_application(user.account, user, %{
        "name" => "Second app",
        "redirect_uris" => "https://example.org/callback"
      })

    assert {:ok, {apps, _meta}} = AccountTokens.list_oauth_applications(user.account)
    assert Enum.sort(Enum.map(apps, & &1.id)) == Enum.sort([first.id, second.id])
  end

  test "get_oauth_application!/2 preloads the owning user" do
    user = TestHelpers.create_user("get-oauth@test.com", "get-oauth")

    {:ok, %{app: app}} =
      AccountTokens.create_oauth_application(user.account, user, %{
        "name" => "Fetched app",
        "redirect_uris" => "https://example.com/callback"
      })

    loaded = AccountTokens.get_oauth_application!(app.id, user.account.id)

    assert loaded.user.id == user.id
  end

  test "update_oauth_application/3 updates the app and emits an event" do
    user = TestHelpers.create_user("update-oauth@test.com", "update-oauth")

    {:ok, %{app: app}} =
      AccountTokens.create_oauth_application(user.account, user, %{
        "name" => "Old app",
        "redirect_uris" => "https://example.com/callback"
      })

    assert {:ok, updated_app} =
             TestHelpers.expect_event(
               "oauth_app.updated",
               fn ->
                 AccountTokens.update_oauth_application(app, %{"name" => "New app"},
                   actor: user,
                   via: :dashboard
                 )
               end,
               %{
                 :account_id => user.account.id,
                 :user_id => user.id,
                 {:opt, :via} => :dashboard,
                 {:opt, :resource_type} => "oauth_application"
               }
             )

    assert updated_app.name == "New app"
  end

  test "regenerate_oauth_application_secret/2 emits an event and returns a new secret" do
    user = TestHelpers.create_user("regen-oauth@test.com", "regen-oauth")

    {:ok, %{app: app, client_secret: original_secret}} =
      AccountTokens.create_oauth_application(user.account, user, %{
        "name" => "Secret app",
        "redirect_uris" => "https://example.com/callback"
      })

    assert {:ok, %{client_secret: regenerated_secret}} =
             TestHelpers.expect_event(
               "oauth_app.secret_regenerated",
               fn ->
                 AccountTokens.regenerate_oauth_application_secret(app, actor: user, via: :api)
               end,
               %{
                 :account_id => user.account.id,
                 :user_id => user.id,
                 {:opt, :via} => :api,
                 {:opt, :resource_type} => "oauth_application"
               }
             )

    assert regenerated_secret
    assert regenerated_secret != original_secret
  end

  test "delete_oauth_application/2 deletes the app and emits an event" do
    user = TestHelpers.create_user("delete-oauth@test.com", "delete-oauth")

    {:ok, %{app: app}} =
      AccountTokens.create_oauth_application(user.account, user, %{
        "name" => "Delete app",
        "redirect_uris" => "https://example.com/callback"
      })

    assert :ok =
             TestHelpers.expect_event(
               "oauth_app.deleted",
               fn -> AccountTokens.delete_oauth_application(app, actor: user, via: :mcp) end,
               %{
                 :account_id => user.account.id,
                 :user_id => user.id,
                 {:opt, :via} => :mcp,
                 {:opt, :resource_type} => "oauth_application"
               }
             )

    refute Repo.get_by(OAuthApplication, id: app.id)
  end
end
