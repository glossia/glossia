defmodule Glossia.Formats.PropertiesHandlerTest do
  use Glossia.FormatCase, async: false

  alias Glossia.Formats.PropertiesHandler

  describe "validate/1" do
    test "accepts valid properties content with =" do
      content = """
      hello=world
      foo=bar
      """

      assert :ok = PropertiesHandler.validate(content)
    end

    test "accepts valid properties content with :" do
      content = """
      hello:world
      foo:bar
      """

      assert :ok = PropertiesHandler.validate(content)
    end

    test "accepts properties with spaces around =" do
      content = """
      hello = world
      foo = bar
      """

      assert :ok = PropertiesHandler.validate(content)
    end

    test "accepts properties with comments starting with #" do
      content = """
      # This is a comment
      hello=world
      """

      assert :ok = PropertiesHandler.validate(content)
    end

    test "accepts properties with comments starting with !" do
      content = """
      ! This is a comment
      hello=world
      """

      assert :ok = PropertiesHandler.validate(content)
    end

    test "accepts properties with empty lines" do
      content = """
      hello=world

      foo=bar
      """

      assert :ok = PropertiesHandler.validate(content)
    end

    test "rejects content with invalid lines (no = or :)" do
      content = """
      hello=world
      this is not valid
      foo=bar
      """

      assert {:error, message} = PropertiesHandler.validate(content)
      assert message =~ "line 2"
    end

    test "rejects completely invalid content" do
      content = """
      just some random text
      without any key value pairs
      """

      assert {:error, _} = PropertiesHandler.validate(content)
    end
  end

  describe "translate/3" do
    test "translates simple properties content" do
      content = """
      hello=Hello
      world=World
      """

      expected = """
      hello=Hola
      world=Mundo
      """

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es",
                                                                      _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = PropertiesHandler.translate(content, "en", "es")
      assert result == expected
    end

    test "preserves comments" do
      content = """
      # Comment
      hello=Hello
      """

      expected = """
      # Comment
      hello=Hola
      """

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es",
                                                                      _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = PropertiesHandler.translate(content, "en", "es")
      assert result =~ "# Comment"
    end

    test "validates input before translation" do
      invalid_content = """
      hello=world
      this is invalid
      """

      assert {:error, _} = PropertiesHandler.translate(invalid_content, "en", "es")
    end

    test "validates output after translation" do
      content = "hello=Hello"
      invalid_output = "broken output without equals"

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es",
                                                                      _instructions ->
        {:ok, invalid_output}
      end)

      assert {:error, _} = PropertiesHandler.translate(content, "en", "es")
    end
  end
end
