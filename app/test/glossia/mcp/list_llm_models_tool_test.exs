defmodule Glossia.MCP.ListLLMModelsToolTest do
  use Glossia.DataCase, async: true

  alias Glossia.LLMModels
  alias Glossia.MCP.ListLLMModelsTool
  alias Glossia.TestHelpers
  alias Hermes.Server.Frame

  @all_scopes Glossia.Policy.list_rules()
              |> Enum.map(&"#{&1.object}:#{&1.action}")
              |> Enum.uniq()

  setup do
    user = TestHelpers.create_user("mcp-list@test.com", "mcp-list")
    %{user: user, account: user.account}
  end

  defp frame_for(user, scopes \\ nil) do
    Frame.new(%{current_user: user, scopes: scopes || @all_scopes})
  end

  defp create_model(account, user, handle) do
    {:ok, model} =
      LLMModels.create_model(account, user, %{
        "handle" => handle,
        "model" => "anthropic:claude-sonnet-4-20250514",
        "api_key" => "sk-test"
      })

    model
  end

  describe "execute/2" do
    test "returns empty list when no models exist", %{user: user, account: account} do
      assert {:reply, response, _frame} =
               ListLLMModelsTool.execute(%{"handle" => account.handle}, frame_for(user))

      [content] = response.content
      result = JSON.decode!(content["text"])
      assert result == []
    end

    test "returns models for the account", %{user: user, account: account} do
      create_model(account, user, "model-a")
      create_model(account, user, "model-b")

      assert {:reply, response, _frame} =
               ListLLMModelsTool.execute(%{"handle" => account.handle}, frame_for(user))

      [content] = response.content
      result = JSON.decode!(content["text"])
      assert length(result) == 2
      handles = Enum.map(result, & &1["handle"]) |> Enum.sort()
      assert handles == ["model-a", "model-b"]
    end

    test "does not include api_key in response", %{user: user, account: account} do
      create_model(account, user, "secret-model")

      assert {:reply, response, _frame} =
               ListLLMModelsTool.execute(%{"handle" => account.handle}, frame_for(user))

      [content] = response.content
      [model] = JSON.decode!(content["text"])
      refute Map.has_key?(model, "api_key")
    end

    test "does not return models from other accounts", %{user: user, account: account} do
      other_user = TestHelpers.create_user("other-list@test.com", "other-list")
      create_model(other_user.account, other_user, "other-model")
      create_model(account, user, "my-model")

      assert {:reply, response, _frame} =
               ListLLMModelsTool.execute(%{"handle" => account.handle}, frame_for(user))

      [content] = response.content
      result = JSON.decode!(content["text"])
      assert length(result) == 1
      assert hd(result)["handle"] == "my-model"
    end

    test "returns error for nonexistent account", %{user: user} do
      assert {:error, _error, _frame} =
               ListLLMModelsTool.execute(%{"handle" => "nonexistent"}, frame_for(user))
    end

    test "returns error when not authenticated", %{account: account} do
      assert {:error, _error, _frame} =
               ListLLMModelsTool.execute(%{"handle" => account.handle}, Frame.new(%{}))
    end

    test "returns error with insufficient scope", %{user: user, account: account} do
      frame = frame_for(user, ["llm_model:write"])

      assert {:error, _error, _frame} =
               ListLLMModelsTool.execute(%{"handle" => account.handle}, frame)
    end
  end
end
