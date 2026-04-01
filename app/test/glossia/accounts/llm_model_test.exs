defmodule Glossia.Accounts.LLMModelTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts.LLMModel

  @valid_attrs %{
    "handle" => "my-model",
    "model" => "anthropic:claude-sonnet-4-20250514",
    "api_key" => "sk-test-key"
  }

  describe "changeset/3 (create)" do
    test "valid with all required fields" do
      changeset = LLMModel.changeset(%LLMModel{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires handle" do
      attrs = Map.delete(@valid_attrs, "handle")
      changeset = LLMModel.changeset(%LLMModel{}, attrs)
      assert %{handle: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires model" do
      attrs = Map.delete(@valid_attrs, "model")
      changeset = LLMModel.changeset(%LLMModel{}, attrs)
      assert %{model: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires api_key" do
      attrs = Map.delete(@valid_attrs, "api_key")
      changeset = LLMModel.changeset(%LLMModel{}, attrs)
      assert %{api_key: ["can't be blank"]} = errors_on(changeset)
    end

    test "handle must start with a letter" do
      attrs = Map.put(@valid_attrs, "handle", "1bad")
      changeset = LLMModel.changeset(%LLMModel{}, attrs)
      assert %{handle: [_]} = errors_on(changeset)
    end

    test "handle rejects uppercase" do
      attrs = Map.put(@valid_attrs, "handle", "BadCase")
      changeset = LLMModel.changeset(%LLMModel{}, attrs)
      assert %{handle: [_]} = errors_on(changeset)
    end

    test "handle allows lowercase letters, numbers, and hyphens" do
      attrs = Map.put(@valid_attrs, "handle", "my-model-2")
      changeset = LLMModel.changeset(%LLMModel{}, attrs)
      assert changeset.valid?
    end

    test "handle must be at least 2 characters" do
      attrs = Map.put(@valid_attrs, "handle", "a")
      changeset = LLMModel.changeset(%LLMModel{}, attrs)
      assert %{handle: [_]} = errors_on(changeset)
    end

    test "model must be in provider:id format" do
      attrs = Map.put(@valid_attrs, "model", "no-colon")
      changeset = LLMModel.changeset(%LLMModel{}, attrs)
      assert %{model: [_]} = errors_on(changeset)
    end

    test "model accepts valid provider:id format" do
      for model <- ["anthropic:claude-sonnet-4-20250514", "openai:gpt-4o", "google:gemini-2.0-flash-001"] do
        attrs = Map.put(@valid_attrs, "model", model)
        changeset = LLMModel.changeset(%LLMModel{}, attrs)
        assert changeset.valid?, "expected #{model} to be valid"
      end
    end
  end

  describe "changeset/3 (update, require_api_key: false)" do
    test "does not require api_key" do
      attrs = Map.delete(@valid_attrs, "api_key")
      changeset = LLMModel.changeset(%LLMModel{}, attrs, require_api_key: false)
      assert changeset.valid?
    end

    test "still requires handle and model" do
      changeset = LLMModel.changeset(%LLMModel{}, %{}, require_api_key: false)
      errors = errors_on(changeset)
      assert %{handle: ["can't be blank"]} = errors
      assert %{model: ["can't be blank"]} = errors
    end

    test "still validates handle format" do
      attrs = %{"handle" => "1bad", "model" => "anthropic:claude-sonnet-4-20250514"}
      changeset = LLMModel.changeset(%LLMModel{}, attrs, require_api_key: false)
      assert %{handle: [_]} = errors_on(changeset)
    end
  end
end
