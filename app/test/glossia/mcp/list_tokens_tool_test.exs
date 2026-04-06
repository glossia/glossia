defmodule Glossia.MCP.ListTokensToolTest do
  use Glossia.DataCase, async: true

  alias Glossia.AccountTokens
  alias Glossia.MCP.ListTokensTool
  alias Glossia.TestHelpers
  alias Hermes.Server.Frame

  @all_scopes Glossia.Policy.list_rules()
              |> Enum.map(&"#{&1.object}:#{&1.action}")
              |> Enum.uniq()

  setup do
    user = TestHelpers.create_user("mcp-list-token@test.com", "mcp-list-token")
    %{user: user, account: user.account}
  end

  defp frame_for(user, scopes \\ nil) do
    Frame.new(%{current_user: user, scopes: scopes || @all_scopes})
  end

  describe "execute/2" do
    test "lists account tokens without exposing token hashes", %{user: user, account: account} do
      {:ok, %{token: token}} =
        AccountTokens.create_account_token(account, user, %{
          "name" => "Listed token",
          "scope" => "voice:read"
        })

      assert {:reply, response, _frame} =
               ListTokensTool.execute(%{"handle" => account.handle}, frame_for(user))

      [content] = response.content
      result = JSON.decode!(content["text"])
      [listed] = result

      assert listed["id"] == token.id
      assert listed["name"] == "Listed token"
      assert listed["scope"] == "voice:read"
      assert listed["token_prefix"] == token.token_prefix
      refute Map.has_key?(listed, "token_hash")
    end

    test "returns an error with insufficient scope", %{user: user, account: account} do
      frame = frame_for(user, ["api_credentials:write"])

      assert {:error, _error, _frame} =
               ListTokensTool.execute(%{"handle" => account.handle}, frame)
    end
  end
end
