defmodule Glossia.Formats.FtlHandlerTest do
  use Glossia.FormatCase, async: false

  alias Glossia.Formats.FtlHandler

  describe "validate/1" do
    test "accepts valid FTL content" do
      content = """
      # Comment
      hello = Hello, World!
      welcome = Welcome, {$name}!
      """

      assert :ok = FtlHandler.validate(content)
    end

    test "accepts empty content" do
      assert :ok = FtlHandler.validate("")
    end
  end

  describe "translate/3" do
    test "translates simple key-value pairs" do
      content = "hello = Hello, World!"
      expected = "hello = ¡Hola, Mundo!"

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es", _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result == expected
    end

    test "preserves comments" do
      content = """
      # This is a comment
      hello = Hello
      """

      expected = """
      # This is a comment
      hello = Hola
      """

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es", _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result =~ "# This is a comment"
      assert result =~ "hello = Hola"
    end

    test "preserves empty lines" do
      content = """
      hello = Hello

      goodbye = Goodbye
      """

      expected = """
      hello = Hola

      goodbye = Adiós
      """

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es", _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")

      lines = String.split(result, "\n")
      # Check that there's an empty line between translations
      assert Enum.at(lines, 1) == ""
    end

    test "translates values with variables" do
      content = "welcome = Welcome, {$name}!"
      expected = "welcome = ¡Bienvenido, {$name}!"

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es", _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result == expected
    end

    test "skips lines with only variables" do
      content = "placeholder = {$value}"
      expected = "placeholder = {$value}"

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es", _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result == expected
    end

    test "skips empty values" do
      content = "empty ="
      expected = "empty ="

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es", _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result == expected
    end

    test "preserves spacing around equals sign" do
      content = "hello   =   Hello"
      expected = "hello   =   Hola"

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es", _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result == expected
    end

    test "handles multiple messages" do
      content = """
      hello = Hello
      world = World
      goodbye = Goodbye
      """

      expected = """
      hello = Hola
      world = Mundo
      goodbye = Adiós
      """

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es", _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result =~ "hello = Hola"
      assert result =~ "world = Mundo"
      assert result =~ "goodbye = Adiós"
    end

    test "handles indented lines (attributes/multiline)" do
      content = """
      welcome = Welcome
          .aria-label = Welcome message
      """

      expected = """
      welcome = Bienvenido
          .aria-label = Welcome message
      """

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es", _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result =~ "welcome = Bienvenido"
      # Attributes (indented lines) are preserved as-is, not translated
      assert result =~ "    .aria-label = Welcome message"
    end

    test "handles translation errors" do
      content = "hello = Hello"

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es", _instructions ->
        {:error, :api_error}
      end)

      assert {:error, :api_error} = FtlHandler.translate(content, "en", "es")
    end

    test "handles mixed content" do
      content = """
      # Header comment

      ## Section
      greeting = Hello, {$name}!

      # Another comment
      farewell = Goodbye
      empty-value =
      only-var = {$placeholder}
      """

      expected = """
      # Header comment

      ## Section
      greeting = Bonjour, {$name}!

      # Another comment
      farewell = Au revoir
      empty-value =
      only-var = {$placeholder}
      """

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "fr", _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = FtlHandler.translate(content, "en", "fr")

      # Verify structure is preserved
      assert result =~ "# Header comment"
      assert result =~ "## Section"
      assert result =~ "greeting = Bonjour, {$name}!"
      assert result =~ "# Another comment"
      assert result =~ "farewell = Au revoir"
      assert result =~ "empty-value ="
      assert result =~ "only-var = {$placeholder}"
    end

    test "preserves line order" do
      content = """
      third = Third
      first = First
      second = Second
      """

      expected = """
      third = Tercero
      first = Primero
      second = Segundo
      """

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es", _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")

      lines = String.split(result, "\n", trim: true)
      assert Enum.at(lines, 0) =~ "third"
      assert Enum.at(lines, 1) =~ "first"
      assert Enum.at(lines, 2) =~ "second"
    end

    test "handles real-world FTL example" do
      content = """
      ## Main Navigation

      nav-home = Home
      nav-about = About Us
      nav-contact = Contact

      ## Messages

      # Welcome message shown on homepage
      welcome-message = Welcome to { $appName }!
          .aria-label = Welcome message

      user-greeting = Hello, { $userName }!
      """

      expected = """
      ## Main Navigation

      nav-home = Inicio
      nav-about = Acerca de
      nav-contact = Contacto

      ## Messages

      # Welcome message shown on homepage
      welcome-message = ¡Bienvenido a { $appName }!
          .aria-label = Welcome message

      user-greeting = ¡Hola, { $userName }!
      """

      expect(Glossia.AI.Translator, :translate_with_instructions, fn ^content, "en", "es", _instructions ->
        {:ok, expected}
      end)

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")

      assert result =~ "## Main Navigation"
      assert result =~ "nav-home = Inicio"
      assert result =~ "## Messages"
      assert result =~ "# Welcome message shown on homepage"
      assert result =~ "welcome-message = ¡Bienvenido a { $appName }!"
      # Attributes (indented lines) are preserved as-is
      assert result =~ "    .aria-label = Welcome message"
    end
  end
end
