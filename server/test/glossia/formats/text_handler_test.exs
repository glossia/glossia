defmodule Glossia.Formats.TextHandlerTest do
  use Glossia.FormatCase, async: false

  alias Glossia.Formats.TextHandler

  describe "validate/1" do
    test "accepts valid text content" do
      content = "Hello, world!"

      assert :ok = TextHandler.validate(content)
    end

    test "accepts empty string" do
      content = ""

      assert :ok = TextHandler.validate(content)
    end

    test "accepts multiline text" do
      content = """
      Line 1
      Line 2
      Line 3
      """

      assert :ok = TextHandler.validate(content)
    end

    test "rejects nil content" do
      assert {:error, "Content cannot be nil"} = TextHandler.validate(nil)
    end

    test "rejects non-string content" do
      assert {:error, "Content must be a string"} = TextHandler.validate(123)
      assert {:error, "Content must be a string"} = TextHandler.validate(%{})
      assert {:error, "Content must be a string"} = TextHandler.validate([])
    end
  end

  describe "translate/3" do
    test "translates simple text content" do
      content = "Hello, world!"
      expected = "Hola, mundo!"

      expect(Glossia.AI.Translator, :translate, fn ^content, "en", "es" ->
        {:ok, expected}
      end)

      assert {:ok, result} = TextHandler.translate(content, "en", "es")
      assert result == expected
    end

    test "validates output after translation" do
      content = "Hello"

      expect(Glossia.AI.Translator, :translate, fn ^content, "en", "es" ->
        {:ok, nil}
      end)

      assert {:error, "Content cannot be nil"} = TextHandler.translate(content, "en", "es")
    end

    test "handles translation errors" do
      content = "Hello"

      expect(Glossia.AI.Translator, :translate, fn ^content, "en", "es" ->
        {:error, :api_error}
      end)

      assert {:error, :api_error} = TextHandler.translate(content, "en", "es")
    end
  end
end
