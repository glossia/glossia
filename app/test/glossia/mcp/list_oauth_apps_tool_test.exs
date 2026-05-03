defmodule Glossia.MCP.ListOAuthAppsToolTest do
  use Glossia.DataCase, async: true

  alias Glossia.AccountTokens
  alias Glossia.MCP.ListOAuthAppsTool
  alias Glossia.TestHelpers
  alias Hermes.Server.Frame

  @all_scopes Glossia.Policy.list_rules()
              |> Enum.map(&"#{&1.object}:#{&1.action}")
              |> Enum.uniq()

  setup do
    user = TestHelpers.create_user("mcp-list-app@test.com", "mcp-list-app")
    %{user: user, account: user.account}
  end

  defp frame_for(user, scopes \\ nil) do
    Frame.new(%{current_user: user, scopes: scopes || @all_scopes})
  end

  describe "execute/2" do
    test "lists oauth applications for an account", %{user: user, account: account} do
      {:ok, %{app: app}} =
        AccountTokens.create_oauth_application(account, user, %{
          "name" => "Companion",
          "description" => "Lists apps",
          "homepage_url" => "https://example.com",
          "redirect_uris" => "https://example.com/callback"
        })

      assert {:reply, response, _frame} =
               ListOAuthAppsTool.execute(%{"handle" => account.handle}, frame_for(user))

      [content] = response.content
      result = JSON.decode!(content["text"])
      [listed] = result

      assert listed["id"] == app.id
      assert listed["name"] == "Companion"
      assert listed["description"] == "Lists apps"
      assert listed["homepage_url"] == "https://example.com"
      assert listed["client_id"] == app.boruta_client_id
    end

    test "returns an error with insufficient scope", %{user: user, account: account} do
      frame = frame_for(user, ["api_credentials:write"])

      assert {:error, _error, _frame} =
               ListOAuthAppsTool.execute(%{"handle" => account.handle}, frame)
    end
  end
end
