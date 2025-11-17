defmodule Glossia.Formats.PoHandlerTest do
  use Glossia.FormatCase, async: false

  alias Glossia.Formats.PoHandler

  describe "validate/1" do
    test "accepts valid PO content" do
      content = """
      msgid "hello"
      msgstr "world"
      """

      assert :ok = PoHandler.validate(content)
    end

    test "accepts PO content with comments" do
      content = """
      # Translator comment
      #: source-reference
      msgid "hello"
      msgstr "world"
      """

      assert :ok = PoHandler.validate(content)
    end

    test "accepts PO content with multiple entries" do
      content = """
      msgid "hello"
      msgstr "hola"

      msgid "goodbye"
      msgstr "adios"
      """

      assert :ok = PoHandler.validate(content)
    end

    test "accepts PO content with empty msgstr" do
      content = """
      msgid "hello"
      msgstr ""
      """

      assert :ok = PoHandler.validate(content)
    end

    test "rejects content missing msgid" do
      content = """
      msgstr "world"
      """

      assert {:error, :invalid_content} = PoHandler.validate(content)
    end

    test "rejects content missing msgstr" do
      content = """
      msgid "hello"
      """

      assert {:error, :invalid_content} = PoHandler.validate(content)
    end

    test "rejects content with mismatched msgid and msgstr" do
      content = """
      msgid "hello"
      msgid "world"
      msgstr "hola"
      """

      assert {:error, :invalid_content} = PoHandler.validate(content)
    end

    test "rejects completely invalid content" do
      content = """
      this is not a PO file
      just random text
      """

      assert {:error, _} = PoHandler.validate(content)
    end
  end

  describe "translate/3" do
    test "translates simple PO content" do
      content = """
      msgid "hello"
      msgstr "Hello"
      """

      expected = """
      msgid "hello"
      msgstr "Hola"
      """

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es",
                                                                      _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = PoHandler.translate(content, "en", "es")
      assert result == expected
    end

    test "preserves comments" do
      content = """
      # Comment
      msgid "hello"
      msgstr "Hello"
      """

      expected = """
      # Comment
      msgid "hello"
      msgstr "Hola"
      """

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es",
                                                                      _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = PoHandler.translate(content, "en", "es")
      assert result =~ "# Comment"
    end

    test "validates output after translation" do
      content = """
      msgid "hello"
      msgstr "Hello"
      """

      invalid_output = "broken output"

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es",
                                                                      _instructions ->
        {:ok, invalid_output}
      end)

      assert {:error, _} = PoHandler.translate(content, "en", "es")
    end
  end
end
