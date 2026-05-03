defmodule Glossia.MCP.CreateTokenToolTest do
  use Glossia.DataCase, async: true

  alias Glossia.AccountTokens
  alias Glossia.MCP.CreateTokenTool
  alias Glossia.TestHelpers
  alias Hermes.Server.Frame

  @all_scopes Glossia.Policy.list_rules()
              |> Enum.map(&"#{&1.object}:#{&1.action}")
              |> Enum.uniq()

  setup do
    user = TestHelpers.create_user("mcp-create-token@test.com", "mcp-create-token")
    %{user: user, account: user.account}
  end

  defp frame_for(user, scopes \\ nil) do
    Frame.new(%{current_user: user, scopes: scopes || @all_scopes})
  end

  describe "execute/2" do
    test "creates a token and returns its plain token", %{user: user, account: account} do
      params = %{
        "handle" => account.handle,
        "name" => "Tool token",
        "description" => "Created from MCP",
        "scope" => "voice:read voice:write",
        "expires_in_days" => 30
      }

      assert {:reply, response, _frame} =
               TestHelpers.expect_event(
                 "token.created",
                 fn -> CreateTokenTool.execute(params, frame_for(user)) end,
                 %{
                   :account_id => account.id,
                   :user_id => user.id,
                   {:opt, :via} => :mcp,
                   {:opt, :resource_type} => "account_token"
                 }
               )

      [content] = response.content
      result = JSON.decode!(content["text"])

      assert result["name"] == "Tool token"
      assert result["scope"] == "voice:read voice:write"
      assert String.starts_with?(result["plain_token"], "glsa_")
      assert result["expires_at"]
    end

    test "persists the token in the database", %{user: user, account: account} do
      params = %{"handle" => account.handle, "name" => "Persisted token"}

      assert {:reply, _response, _frame} = CreateTokenTool.execute(params, frame_for(user))

      {:ok, {tokens, _meta}} = AccountTokens.list_account_tokens(account)
      assert Enum.any?(tokens, &(&1.name == "Persisted token"))
    end

    test "returns an error when unauthenticated", %{account: account} do
      params = %{"handle" => account.handle, "name" => "No auth"}

      assert {:error, _error, _frame} = CreateTokenTool.execute(params, Frame.new(%{}))
    end

    test "returns an error with insufficient scope", %{user: user, account: account} do
      params = %{"handle" => account.handle, "name" => "No scope"}

      assert {:error, _error, _frame} =
               CreateTokenTool.execute(params, frame_for(user, ["api_credentials:read"]))
    end
  end
end
