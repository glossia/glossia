defmodule Glossia.LLMModelsTest do
  use Glossia.DataCase, async: true

  alias Glossia.LLMModels
  alias Glossia.TestHelpers

  setup do
    user = TestHelpers.create_user("llm-ctx@test.com", "llm-ctx")
    %{user: user, account: user.account}
  end

  defp valid_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        "handle" => "model-#{System.unique_integer([:positive])}",
        "model" => "anthropic:claude-sonnet-4-20250514",
        "api_key" => "sk-test-key-123"
      },
      overrides
    )
  end

  describe "create_model/3" do
    test "creates a model with valid attrs", %{user: user, account: account} do
      assert {:ok, model} =
               TestHelpers.expect_event(
                 "llm_model.created",
                 fn ->
                   LLMModels.create_model(account, user, valid_attrs())
                 end,
                 %{
                   {:opt, :resource_type} => "llm_model",
                   :account_id => account.id,
                   :user_id => user.id
                 }
               )

      assert model.handle
      assert model.model == "anthropic:claude-sonnet-4-20250514"
      assert model.account_id == account.id
      assert model.created_by_id == user.id
    end

    test "encrypts the api_key", %{user: user, account: account} do
      {:ok, model} =
        LLMModels.create_model(account, user, valid_attrs(%{"api_key" => "sk-secret"}))

      assert model.api_key == "sk-secret"
    end

    test "returns error for missing required fields", %{user: user, account: account} do
      assert {:error, changeset} = LLMModels.create_model(account, user, %{})
      assert errors_on(changeset) |> Map.has_key?(:handle)
      assert errors_on(changeset) |> Map.has_key?(:model)
      assert errors_on(changeset) |> Map.has_key?(:api_key)
    end

    test "returns error for duplicate handle in same account", %{user: user, account: account} do
      attrs = valid_attrs(%{"handle" => "dupe"})
      assert {:ok, _} = LLMModels.create_model(account, user, attrs)
      assert {:error, changeset} = LLMModels.create_model(account, user, attrs)
      assert errors_on(changeset) |> Map.has_key?(:handle)
    end

    test "allows same handle in different accounts", %{user: user, account: account} do
      other_user = TestHelpers.create_user("llm-other@test.com", "llm-other")
      attrs = valid_attrs(%{"handle" => "shared-handle"})

      assert {:ok, _} = LLMModels.create_model(account, user, attrs)
      assert {:ok, _} = LLMModels.create_model(other_user.account, other_user, attrs)
    end
  end

  describe "update_model/4" do
    test "updates handle and model", %{user: user, account: account} do
      {:ok, model} = LLMModels.create_model(account, user, valid_attrs())

      assert {:ok, updated} =
               TestHelpers.expect_event(
                 "llm_model.updated",
                 fn ->
                   LLMModels.update_model(account, user, model, %{
                     "handle" => "updated-handle",
                     "model" => "openai:gpt-4o"
                   })
                 end,
                 %{
                   {:opt, :resource_type} => "llm_model",
                   :account_id => account.id,
                   :user_id => user.id
                 }
               )

      assert updated.handle == "updated-handle"
      assert updated.model == "openai:gpt-4o"
    end

    test "does not require api_key on update", %{user: user, account: account} do
      {:ok, model} =
        LLMModels.create_model(account, user, valid_attrs(%{"api_key" => "sk-original"}))

      assert {:ok, updated} =
               LLMModels.update_model(account, user, model, %{"handle" => "new-handle"})

      assert updated.api_key == "sk-original"
    end

    test "updates api_key when provided", %{user: user, account: account} do
      {:ok, model} = LLMModels.create_model(account, user, valid_attrs())

      assert {:ok, updated} =
               LLMModels.update_model(account, user, model, %{"api_key" => "sk-new-key"})

      assert updated.api_key == "sk-new-key"
    end
  end

  describe "delete_model/3" do
    test "deletes the model", %{user: user, account: account} do
      {:ok, model} = LLMModels.create_model(account, user, valid_attrs())

      assert {:ok, _deleted} =
               TestHelpers.expect_event(
                 "llm_model.deleted",
                 fn ->
                   LLMModels.delete_model(account, user, model)
                 end,
                 %{
                   {:opt, :resource_type} => "llm_model",
                   :account_id => account.id,
                   :user_id => user.id
                 }
               )

      assert LLMModels.get_model(model.id, account.id) == nil
    end
  end

  describe "list_models/2" do
    test "returns models for the account", %{user: user, account: account} do
      {:ok, _} = LLMModels.create_model(account, user, valid_attrs(%{"handle" => "list-a"}))
      {:ok, _} = LLMModels.create_model(account, user, valid_attrs(%{"handle" => "list-b"}))

      assert {:ok, {models, _meta}} = LLMModels.list_models(account)
      assert length(models) == 2
    end

    test "does not return models from other accounts", %{user: user, account: account} do
      other_user = TestHelpers.create_user("llm-iso@test.com", "llm-iso")
      {:ok, _} = LLMModels.create_model(account, user, valid_attrs(%{"handle" => "mine"}))

      {:ok, _} =
        LLMModels.create_model(
          other_user.account,
          other_user,
          valid_attrs(%{"handle" => "theirs"})
        )

      assert {:ok, {models, _meta}} = LLMModels.list_models(account)
      assert length(models) == 1
      assert hd(models).handle == "mine"
    end
  end

  describe "get_model/2 and get_model!/2" do
    test "returns model by id and account", %{user: user, account: account} do
      {:ok, model} = LLMModels.create_model(account, user, valid_attrs())
      assert LLMModels.get_model(model.id, account.id).id == model.id
    end

    test "returns nil for wrong account", %{user: user, account: account} do
      other_user = TestHelpers.create_user("llm-get@test.com", "llm-get")
      {:ok, model} = LLMModels.create_model(account, user, valid_attrs())
      assert LLMModels.get_model(model.id, other_user.account.id) == nil
    end

    test "get_model! raises for missing model", %{account: account} do
      assert_raise Ecto.NoResultsError, fn ->
        LLMModels.get_model!(Ecto.UUID.generate(), account.id)
      end
    end
  end

  describe "get_model_by_handle/2" do
    test "returns model by handle", %{user: user, account: account} do
      {:ok, _} = LLMModels.create_model(account, user, valid_attrs(%{"handle" => "by-handle"}))
      assert LLMModels.get_model_by_handle("by-handle", account.id).handle == "by-handle"
    end

    test "returns nil for nonexistent handle", %{account: account} do
      assert LLMModels.get_model_by_handle("nonexistent", account.id) == nil
    end
  end
end
