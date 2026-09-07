defmodule Glossia.MCP.RevokeTokenToolTest do
  use Glossia.DataCase, async: true

  alias Glossia.AccountTokens
  alias Glossia.MCP.RevokeTokenTool
  alias Glossia.TestHelpers
  alias Hermes.Server.Frame

  @all_scopes Glossia.Policy.list_rules()
              |> Enum.map(&"#{&1.object}:#{&1.action}")
              |> Enum.uniq()

  setup do
    user = TestHelpers.create_user("mcp-revoke-token@test.com", "mcp-revoke-token")
    %{user: user, account: user.account}
  end

  defp frame_for(user, scopes \\ nil) do
    Frame.new(%{current_user: user, scopes: scopes || @all_scopes})
  end

  describe "execute/2" do
    test "revokes a token and returns success", %{user: user, account: account} do
      {:ok, %{token: token}} =
        AccountTokens.create_account_token(account, user, %{"name" => "Revoke me"})

      assert {:reply, response, _frame} =
               TestHelpers.expect_event(
                 "token.revoked",
                 fn ->
                   RevokeTokenTool.execute(
                     %{"handle" => account.handle, "token_id" => token.id},
                     frame_for(user)
                   )
                 end,
                 %{
                   :account_id => account.id,
                   :user_id => user.id,
                   {:opt, :via} => :mcp,
                   {:opt, :resource_type} => "account_token"
                 }
               )

      [content] = response.content
      result = JSON.decode!(content["text"])

      assert result["status"] == "revoked"
      assert AccountTokens.get_account_token!(token.id, account.id).revoked_at
    end

    test "returns an error for nonexistent token", %{user: user, account: account} do
      assert {:error, _error, _frame} =
               RevokeTokenTool.execute(
                 %{"handle" => account.handle, "token_id" => Ecto.UUID.generate()},
                 frame_for(user)
               )
    end

    test "returns an error with insufficient scope", %{user: user, account: account} do
      frame = frame_for(user, ["api_credentials:read"])

      assert {:error, _error, _frame} =
               RevokeTokenTool.execute(
                 %{"handle" => account.handle, "token_id" => Ecto.UUID.generate()},
                 frame
               )
    end
  end
end
