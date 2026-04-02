defmodule Glossia.Accounts.LLMModelTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts.LLMModel

  describe "changeset/3" do
    test "valid with all required fields" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "my-model",
          "model" => "anthropic:claude-sonnet-4-20250514",
          "api_key" => "sk-test"
        })

      assert changeset.valid?
    end

    test "invalid without handle" do
      changeset = LLMModel.changeset(%LLMModel{}, %{"model" => "anthropic:test", "api_key" => "sk"})
      assert errors_on(changeset) |> Map.has_key?(:handle)
    end

    test "invalid without model" do
      changeset = LLMModel.changeset(%LLMModel{}, %{"handle" => "test", "api_key" => "sk"})
      assert errors_on(changeset) |> Map.has_key?(:model)
    end

    test "invalid without api_key when require_api_key is true" do
      changeset = LLMModel.changeset(%LLMModel{}, %{"handle" => "test", "model" => "anthropic:test"})
      assert errors_on(changeset) |> Map.has_key?(:api_key)
    end

    test "valid without api_key when require_api_key is false" do
      changeset =
        LLMModel.changeset(
          %LLMModel{},
          %{"handle" => "test", "model" => "anthropic:test"},
          require_api_key: false
        )

      refute errors_on(changeset) |> Map.has_key?(:api_key)
    end

    test "handle must start with a letter" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "1bad",
          "model" => "anthropic:test",
          "api_key" => "sk"
        })

      assert errors_on(changeset) |> Map.has_key?(:handle)
    end

    test "handle must not contain uppercase" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "BadHandle",
          "model" => "anthropic:test",
          "api_key" => "sk"
        })

      assert errors_on(changeset) |> Map.has_key?(:handle)
    end

    test "handle allows hyphens" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "my-great-model",
          "model" => "anthropic:test",
          "api_key" => "sk"
        })

      assert changeset.valid?
    end

    test "handle minimum length is 2" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "a",
          "model" => "anthropic:test",
          "api_key" => "sk"
        })

      assert errors_on(changeset) |> Map.has_key?(:handle)
    end

    test "handle maximum length is 64" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => String.duplicate("a", 65),
          "model" => "anthropic:test",
          "api_key" => "sk"
        })

      assert errors_on(changeset) |> Map.has_key?(:handle)
    end

    test "model must be in provider:model format" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "test",
          "model" => "no-colon-here",
          "api_key" => "sk"
        })

      assert errors_on(changeset) |> Map.has_key?(:model)
    end

    test "model accepts valid provider:model format" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "test",
          "model" => "openai:gpt-4o",
          "api_key" => "sk"
        })

      assert changeset.valid?
    end
  end
end
