defmodule Glossia.MCP.ListLLMModelsToolTest do
  use Glossia.DataCase, async: true

  alias Glossia.LLMModels
  alias Glossia.MCP.ListLLMModelsTool
  alias Glossia.TestHelpers
  alias Hermes.Server.Frame

  setup do
    user = TestHelpers.create_user("mcp-list@test.com", "mcp-list")
    %{user: user, account: user.account}
  end

  @all_scopes Glossia.Policy.list_rules()
             |> Enum.map(&"#{&1.object}:#{&1.action}")
             |> Enum.uniq()

  defp frame_for(user, scopes \\ nil) do
    Frame.new(%{current_user: user, scopes: scopes || @all_scopes})
  end

  describe "execute/2" do
    test "returns models for the account", %{user: user, account: account} do
      {:ok, _} =
        LLMModels.create_model(account, user, %{
          "handle" => "test-model",
          "model" => "anthropic:claude-sonnet-4-20250514",
          "api_key" => "sk-test"
        })

      assert {:reply, response, _frame} =
               ListLLMModelsTool.execute(%{"handle" => account.handle}, frame_for(user))

      [content] = response.content
      models = JSON.decode!(content["text"])
      assert length(models) == 1
      assert hd(models)["handle"] == "test-model"
      assert hd(models)["model"] == "anthropic:claude-sonnet-4-20250514"
    end

    test "returns empty list when no models configured", %{user: user, account: account} do
      assert {:reply, response, _frame} =
               ListLLMModelsTool.execute(%{"handle" => account.handle}, frame_for(user))

      [content] = response.content
      assert JSON.decode!(content["text"]) == []
    end

    test "does not leak models from other accounts", %{user: user, account: account} do
      other_user = TestHelpers.create_user("other-mcp@test.com", "other-mcp")

      {:ok, _} =
        LLMModels.create_model(other_user.account, other_user, %{
          "handle" => "their-model",
          "model" => "openai:gpt-4o",
          "api_key" => "sk-other"
        })

      assert {:reply, response, _frame} =
               ListLLMModelsTool.execute(%{"handle" => account.handle}, frame_for(user))

      [content] = response.content
      assert JSON.decode!(content["text"]) == []
    end

    test "returns error for nonexistent account", %{user: user} do
      assert {:error, _error, _frame} =
               ListLLMModelsTool.execute(%{"handle" => "nonexistent"}, frame_for(user))
    end

    test "returns error when not authenticated" do
      frame = Frame.new(%{})

      assert {:error, _error, _frame} =
               ListLLMModelsTool.execute(%{"handle" => "any"}, frame)
    end

    test "returns error with insufficient scope", %{user: user, account: account} do
      frame = frame_for(user, ["voice:read"])

      assert {:error, _error, _frame} =
               ListLLMModelsTool.execute(%{"handle" => account.handle}, frame)
    end

    test "does not include api_key in response", %{user: user, account: account} do
      {:ok, _} =
        LLMModels.create_model(account, user, %{
          "handle" => "secret-model",
          "model" => "anthropic:claude-sonnet-4-20250514",
          "api_key" => "sk-super-secret"
        })

      assert {:reply, response, _frame} =
               ListLLMModelsTool.execute(%{"handle" => account.handle}, frame_for(user))

      [content] = response.content
      [model] = JSON.decode!(content["text"])
      refute Map.has_key?(model, "api_key")
    end
  end
end
