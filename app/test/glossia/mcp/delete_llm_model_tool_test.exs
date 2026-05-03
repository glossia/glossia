defmodule Glossia.MCP.DeleteLLMModelToolTest do
  use Glossia.DataCase, async: true

  alias Glossia.LLMModels
  alias Glossia.MCP.DeleteLLMModelTool
  alias Glossia.TestHelpers
  alias Hermes.Server.Frame

  @all_scopes Glossia.Policy.list_rules()
              |> Enum.map(&"#{&1.object}:#{&1.action}")
              |> Enum.uniq()

  setup do
    user = TestHelpers.create_user("mcp-delete@test.com", "mcp-delete")

    {:ok, model} =
      LLMModels.create_model(user.account, user, %{
        "handle" => "to-delete-#{System.unique_integer([:positive])}",
        "model" => "openai:gpt-4o",
        "api_key" => "sk-delete-test"
      })

    %{user: user, account: user.account, model: model}
  end

  defp frame_for(user, scopes \\ nil) do
    Frame.new(%{current_user: user, scopes: scopes || @all_scopes})
  end

  describe "execute/2" do
    test "deletes the model", %{user: user, account: account, model: model} do
      params = %{"handle" => account.handle, "model_id" => model.id}

      assert {:reply, response, _frame} =
               TestHelpers.expect_event(
                 "llm_model.deleted",
                 fn ->
                   DeleteLLMModelTool.execute(params, frame_for(user))
                 end,
                 %{
                   {:opt, :resource_type} => "llm_model",
                   :account_id => account.id,
                   :user_id => user.id
                 }
               )

      [content] = response.content
      result = JSON.decode!(content["text"])
      assert result["status"] == "deleted"
      assert result["handle"] == model.handle
    end

    test "removes the model from the database", %{user: user, account: account, model: model} do
      params = %{"handle" => account.handle, "model_id" => model.id}
      assert {:reply, _, _} = DeleteLLMModelTool.execute(params, frame_for(user))
      assert is_nil(LLMModels.get_model(model.id, account.id))
    end

    test "returns error for nonexistent model", %{user: user, account: account} do
      params = %{"handle" => account.handle, "model_id" => Ecto.UUID.generate()}
      assert {:error, _error, _frame} = DeleteLLMModelTool.execute(params, frame_for(user))
    end

    test "returns error for model on different account", %{user: user, model: model} do
      other_user = TestHelpers.create_user("other-del@test.com", "other-del")
      params = %{"handle" => other_user.account.handle, "model_id" => model.id}
      assert {:error, _error, _frame} = DeleteLLMModelTool.execute(params, frame_for(user))
    end

    test "returns error for nonexistent account", %{user: user, model: model} do
      params = %{"handle" => "nonexistent", "model_id" => model.id}
      assert {:error, _error, _frame} = DeleteLLMModelTool.execute(params, frame_for(user))
    end

    test "returns error when not authenticated", %{account: account, model: model} do
      params = %{"handle" => account.handle, "model_id" => model.id}
      assert {:error, _error, _frame} = DeleteLLMModelTool.execute(params, Frame.new(%{}))
    end

    test "returns error with insufficient scope", %{user: user, account: account, model: model} do
      params = %{"handle" => account.handle, "model_id" => model.id}
      frame = frame_for(user, ["llm_model:read"])
      assert {:error, _error, _frame} = DeleteLLMModelTool.execute(params, frame)
    end
  end
end
