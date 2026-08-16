defmodule Glossia.Accounts.LLMModelTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts.LLMModel

  describe "changeset/3" do
    test "valid with all required fields" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "my-model",
          "model" => "anthropic/claude-sonnet-4-20250514",
          "api_key" => "sk-test"
        })

      assert changeset.valid?
    end

    test "invalid without handle" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{"model" => "anthropic/test", "api_key" => "sk"})

      assert errors_on(changeset) |> Map.has_key?(:handle)
    end

    test "invalid without model" do
      changeset = LLMModel.changeset(%LLMModel{}, %{"handle" => "test", "api_key" => "sk"})
      assert errors_on(changeset) |> Map.has_key?(:model)
    end

    test "invalid without api_key when require_api_key is true" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{"handle" => "test", "model" => "anthropic/test"})

      assert errors_on(changeset) |> Map.has_key?(:api_key)
    end

    test "valid without api_key when require_api_key is false" do
      changeset =
        LLMModel.changeset(
          %LLMModel{},
          %{"handle" => "test", "model" => "anthropic/test"},
          require_api_key: false
        )

      refute errors_on(changeset) |> Map.has_key?(:api_key)
    end

    test "casts a valid base_url" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "gw",
          "model" => "anthropic/test",
          "api_key" => "sk",
          "base_url" => "http://glossia-bifrost.glossia.svc.cluster.local:8080/v1"
        })

      assert changeset.valid?

      assert changeset.changes[:base_url] ==
               "http://glossia-bifrost.glossia.svc.cluster.local:8080/v1"
    end

    test "normalizes blank and whitespace base_url to nil" do
      for blank <- ["", "   "] do
        changeset =
          LLMModel.changeset(%LLMModel{}, %{
            "handle" => "gw",
            "model" => "anthropic/test",
            "api_key" => "sk",
            "base_url" => blank
          })

        assert changeset.valid?
        assert changeset.changes[:base_url] == nil
      end
    end

    test "rejects base_url without an http/https scheme" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "gw",
          "model" => "anthropic/test",
          "api_key" => "sk",
          "base_url" => "api.together.ai/v1"
        })

      refute changeset.valid?
      assert {:base_url, _} = errors_on(changeset) |> Enum.find(&(elem(&1, 0) == :base_url))
    end

    test "handle must start with a letter" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "1bad",
          "model" => "anthropic/test",
          "api_key" => "sk"
        })

      assert errors_on(changeset) |> Map.has_key?(:handle)
    end

    test "handle must not contain uppercase" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "BadHandle",
          "model" => "anthropic/test",
          "api_key" => "sk"
        })

      assert errors_on(changeset) |> Map.has_key?(:handle)
    end

    test "handle allows hyphens" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "my-great-model",
          "model" => "anthropic/test",
          "api_key" => "sk"
        })

      assert changeset.valid?
    end

    test "handle minimum length is 2" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "a",
          "model" => "anthropic/test",
          "api_key" => "sk"
        })

      assert errors_on(changeset) |> Map.has_key?(:handle)
    end

    test "handle maximum length is 64" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => String.duplicate("a", 65),
          "model" => "anthropic/test",
          "api_key" => "sk"
        })

      assert errors_on(changeset) |> Map.has_key?(:handle)
    end

    test "model must be in provider/model format" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "test",
          "model" => "no-colon-here",
          "api_key" => "sk"
        })

      assert errors_on(changeset) |> Map.has_key?(:model)
    end

    test "model accepts valid provider/model format" do
      changeset =
        LLMModel.changeset(%LLMModel{}, %{
          "handle" => "test",
          "model" => "openai/gpt-4o",
          "api_key" => "sk"
        })

      assert changeset.valid?
    end
  end

  describe "available_models/0" do
    test "uses canonical identifiers and excludes deprecated Together AI models" do
      identifiers =
        LLMModel.available_models()
        |> Enum.flat_map(fn {_provider, models} -> Enum.map(models, &elem(&1, 1)) end)

      assert "togetherai/moonshotai/Kimi-K2.7-Code" in identifiers
      refute "togetherai/moonshotai/Kimi-K2.5" in identifiers
    end
  end
end
