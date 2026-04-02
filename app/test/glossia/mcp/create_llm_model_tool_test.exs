defmodule Glossia.MCP.CreateLLMModelToolTest do
  use Glossia.DataCase, async: true

  alias Glossia.LLMModels
  alias Glossia.MCP.CreateLLMModelTool
  alias Glossia.TestHelpers
  alias Hermes.Server.Frame

  @all_scopes Glossia.Policy.list_rules()
              |> Enum.map(&"#{&1.object}:#{&1.action}")
              |> Enum.uniq()

  setup do
    user = TestHelpers.create_user("mcp-create@test.com", "mcp-create")
    %{user: user, account: user.account}
  end

  defp frame_for(user, scopes \\ nil) do
    Frame.new(%{current_user: user, scopes: scopes || @all_scopes})
  end

  defp valid_params(account) do
    %{
      "handle" => account.handle,
      "model_handle" => "new-model-#{System.unique_integer([:positive])}",
      "model" => "anthropic:claude-sonnet-4-20250514",
      "api_key" => "sk-test-key"
    }
  end

  describe "execute/2" do
    test "creates a model and returns it", %{user: user, account: account} do
      params = valid_params(account)

      assert {:reply, response, _frame} =
               CreateLLMModelTool.execute(params, frame_for(user))

      [content] = response.content
      result = JSON.decode!(content["text"])
      assert result["handle"] == params["model_handle"]
      assert result["model"] == "anthropic:claude-sonnet-4-20250514"
      assert result["id"]
    end

    test "persists the model in the database", %{user: user, account: account} do
      params = valid_params(account)
      assert {:reply, _response, _frame} = CreateLLMModelTool.execute(params, frame_for(user))

      assert model = LLMModels.get_model_by_handle(params["model_handle"], account.id)
      assert model.model == "anthropic:claude-sonnet-4-20250514"
    end

    test "returns error for duplicate handle", %{user: user, account: account} do
      params = valid_params(account)
      assert {:reply, _, _} = CreateLLMModelTool.execute(params, frame_for(user))
      assert {:error, _error, _frame} = CreateLLMModelTool.execute(params, frame_for(user))
    end

    test "returns error for nonexistent account", %{user: user, account: account} do
      params = valid_params(account) |> Map.put("handle", "nonexistent")
      assert {:error, _error, _frame} = CreateLLMModelTool.execute(params, frame_for(user))
    end

    test "returns error when not authenticated", %{account: account} do
      params = valid_params(account)
      assert {:error, _error, _frame} = CreateLLMModelTool.execute(params, Frame.new(%{}))
    end

    test "returns error with insufficient scope", %{user: user, account: account} do
      params = valid_params(account)
      frame = frame_for(user, ["llm_model:read"])
      assert {:error, _error, _frame} = CreateLLMModelTool.execute(params, frame)
    end

    test "does not include api_key in response", %{user: user, account: account} do
      params = valid_params(account)

      assert {:reply, response, _frame} =
               CreateLLMModelTool.execute(params, frame_for(user))

      [content] = response.content
      result = JSON.decode!(content["text"])
      refute Map.has_key?(result, "api_key")
    end
  end
end
