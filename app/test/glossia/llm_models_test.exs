defmodule Glossia.LLMModelsTest do
  use Glossia.DataCase, async: true

  alias Glossia.LLMModels
  alias GlossiaWeb.ApiTestHelpers

  setup do
    user = ApiTestHelpers.create_user("llm-test@test.com", "llm-test")
    %{user: user, account: user.account}
  end

  defp valid_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        "handle" => "test-model-#{System.unique_integer([:positive])}",
        "model" => "anthropic:claude-sonnet-4-20250514",
        "api_key" => "sk-test-key"
      },
      overrides
    )
  end

  describe "create_model/3" do
    test "creates a model with valid attrs", %{account: account, user: user} do
      assert {:ok, model} = LLMModels.create_model(account, user, valid_attrs())
      assert model.model == "anthropic:claude-sonnet-4-20250514"
      assert model.account_id == account.id
      assert model.created_by_id == user.id
    end

    test "returns error with invalid attrs", %{account: account, user: user} do
      assert {:error, changeset} = LLMModels.create_model(account, user, %{})
      assert %{handle: ["can't be blank"]} = errors_on(changeset)
    end

    test "enforces unique handle per account", %{account: account, user: user} do
      attrs = valid_attrs(%{"handle" => "duplicate"})
      assert {:ok, _} = LLMModels.create_model(account, user, attrs)
      assert {:error, changeset} = LLMModels.create_model(account, user, attrs)
      errors = errors_on(changeset)
      assert errors[:handle] || errors[:account_id]
    end

    test "allows same handle on different accounts", %{user: user} do
      other_user = ApiTestHelpers.create_user("other@test.com", "other")
      attrs = valid_attrs(%{"handle" => "shared-handle"})
      assert {:ok, _} = LLMModels.create_model(user.account, user, attrs)
      assert {:ok, _} = LLMModels.create_model(other_user.account, other_user, attrs)
    end
  end

  describe "list_models/2" do
    test "returns models for the given account", %{account: account, user: user} do
      {:ok, _} = LLMModels.create_model(account, user, valid_attrs(%{"handle" => "model-a"}))
      {:ok, _} = LLMModels.create_model(account, user, valid_attrs(%{"handle" => "model-b"}))

      assert {:ok, {models, _meta}} = LLMModels.list_models(account)
      assert length(models) == 2
    end

    test "does not return models from other accounts", %{account: account, user: user} do
      other_user = ApiTestHelpers.create_user("other2@test.com", "other2")
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

  describe "get_model/2" do
    test "returns the model when it exists", %{account: account, user: user} do
      {:ok, created} = LLMModels.create_model(account, user, valid_attrs())
      assert model = LLMModels.get_model(created.id, account.id)
      assert model.id == created.id
    end

    test "returns nil for wrong account", %{account: account, user: user} do
      other_user = ApiTestHelpers.create_user("other3@test.com", "other3")
      {:ok, created} = LLMModels.create_model(account, user, valid_attrs())
      assert is_nil(LLMModels.get_model(created.id, other_user.account.id))
    end

    test "returns nil for nonexistent id", %{account: account} do
      assert is_nil(LLMModels.get_model(Ecto.UUID.generate(), account.id))
    end
  end

  describe "get_model_by_handle/2" do
    test "returns the model by handle", %{account: account, user: user} do
      {:ok, created} = LLMModels.create_model(account, user, valid_attrs(%{"handle" => "by-handle"}))
      assert model = LLMModels.get_model_by_handle("by-handle", account.id)
      assert model.id == created.id
    end

    test "returns nil for wrong account", %{account: account, user: user} do
      other_user = ApiTestHelpers.create_user("other4@test.com", "other4")
      {:ok, _} = LLMModels.create_model(account, user, valid_attrs(%{"handle" => "scoped"}))
      assert is_nil(LLMModels.get_model_by_handle("scoped", other_user.account.id))
    end
  end

  describe "update_model/2" do
    test "updates model fields", %{account: account, user: user} do
      {:ok, model} = LLMModels.create_model(account, user, valid_attrs())
      assert {:ok, updated} = LLMModels.update_model(model, %{"handle" => "new-handle"})
      assert updated.handle == "new-handle"
    end

    test "does not require api_key on update", %{account: account, user: user} do
      {:ok, model} = LLMModels.create_model(account, user, valid_attrs())
      assert {:ok, updated} = LLMModels.update_model(model, %{"model" => "openai:gpt-4o"})
      assert updated.model == "openai:gpt-4o"
    end
  end

  describe "delete_model/1" do
    test "deletes the model", %{account: account, user: user} do
      {:ok, model} = LLMModels.create_model(account, user, valid_attrs())
      assert {:ok, _} = LLMModels.delete_model(model)
      assert is_nil(LLMModels.get_model(model.id, account.id))
    end
  end
end
