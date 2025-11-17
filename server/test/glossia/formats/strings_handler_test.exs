defmodule Glossia.Formats.StringsHandlerTest do
  use Glossia.FormatCase, async: false

  alias Glossia.Formats.StringsHandler

  describe "validate/1" do
    test "accepts valid .strings content" do
      content = """
      "hello" = "world";
      "foo" = "bar";
      """

      assert :ok = StringsHandler.validate(content)
    end

    test "accepts .strings with line comments" do
      content = """
      // This is a comment
      "hello" = "world";
      """

      assert :ok = StringsHandler.validate(content)
    end

    test "accepts .strings with # comments" do
      content = """
      # This is a comment
      "hello" = "world";
      """

      assert :ok = StringsHandler.validate(content)
    end

    test "accepts .strings with block comments" do
      content = """
      /* This is a
         block comment */
      "hello" = "world";
      """

      assert :ok = StringsHandler.validate(content)
    end

    test "accepts .strings with empty lines" do
      content = """
      "hello" = "world";

      "foo" = "bar";
      """

      assert :ok = StringsHandler.validate(content)
    end

    test "accepts .strings with spaces around =" do
      content = """
      "hello"   =   "world";
      """

      assert :ok = StringsHandler.validate(content)
    end

    test "rejects content without semicolon" do
      content = """
      "hello" = "world"
      """

      assert {:error, message} = StringsHandler.validate(content)
      assert message =~ "line 1"
    end

    test "rejects content without equals sign" do
      content = """
      "hello" "world";
      """

      assert {:error, message} = StringsHandler.validate(content)
      assert message =~ "line 1"
    end

    test "rejects completely invalid content" do
      content = """
      just some random text
      """

      assert {:error, _} = StringsHandler.validate(content)
    end

    test "handles multiline block comments correctly" do
      content = """
      /* Start of block
      "hello" = "world";
      End of block */
      "foo" = "bar";
      """

      assert :ok = StringsHandler.validate(content)
    end
  end

  describe "translate/3" do
    test "translates simple .strings content" do
      content = """
      "hello" = "Hello";
      "world" = "World";
      """

      expected = """
      "hello" = "Hola";
      "world" = "Mundo";
      """

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es",
                                                                      _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = StringsHandler.translate(content, "en", "es")
      assert result == expected
    end

    test "preserves comments" do
      content = """
      // Comment
      "hello" = "Hello";
      """

      expected = """
      // Comment
      "hello" = "Hola";
      """

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es",
                                                                      _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = StringsHandler.translate(content, "en", "es")
      assert result =~ "// Comment"
    end

    test "validates input before translation" do
      invalid_content = """
      "hello" = "world"
      """

      assert {:error, _} = StringsHandler.translate(invalid_content, "en", "es")
    end

    test "validates output after translation" do
      content = "\"hello\" = \"Hello\";"
      invalid_output = "broken output"

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es",
                                                                      _instructions ->
        {:ok, invalid_output}
      end)

      assert {:error, _} = StringsHandler.translate(content, "en", "es")
    end
  end
end
