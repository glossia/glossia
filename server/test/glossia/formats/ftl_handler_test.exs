defmodule Glossia.Formats.FtlHandlerTest do
  use Glossia.FormatCase, async: true

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

      expect_translate("Hello, World!", "en", "es", "¡Hola, Mundo!")

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result == "hello = ¡Hola, Mundo!"
    end

    test "preserves comments" do
      content = """
      # This is a comment
      hello = Hello
      """

      expect_translate("Hello", "en", "es", "Hola")

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result =~ "# This is a comment"
      assert result =~ "hello = Hola"
    end

    test "preserves empty lines" do
      content = """
      hello = Hello

      goodbye = Goodbye
      """

      expect_translate("Hello", "en", "es", "Hola")
      expect_translate("Goodbye", "en", "es", "Adiós")

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")

      lines = String.split(result, "\n")
      # Check that there's an empty line between translations
      assert Enum.at(lines, 1) == ""
    end

    test "translates values with variables" do
      content = "welcome = Welcome, {$name}!"

      expect_translate("Welcome, {$name}!", "en", "es", "¡Bienvenido, {$name}!")

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result == "welcome = ¡Bienvenido, {$name}!"
    end

    test "skips lines with only variables" do
      content = "placeholder = {$value}"

      # Should not call translate since it's only variables
      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result == "placeholder = {$value}"
    end

    test "skips empty values" do
      content = "empty ="

      # Should not call translate since value is empty
      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result == "empty ="
    end

    test "preserves spacing around equals sign" do
      content = "hello   =   Hello"

      expect_translate("Hello", "en", "es", "Hola")

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result == "hello   = Hola"
    end

    test "handles multiple messages" do
      content = """
      hello = Hello
      world = World
      goodbye = Goodbye
      """

      expect_translate("Hello", "en", "es", "Hola")
      expect_translate("World", "en", "es", "Mundo")
      expect_translate("Goodbye", "en", "es", "Adiós")

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

      # Two lines will attempt translation
      expect_translate("Welcome", "en", "es", "Bienvenido")
      expect_translate("Welcome message", "en", "es", "Mensaje de bienvenida")

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")
      assert result =~ "welcome = Bienvenido"
      assert result =~ "    .aria-label = Mensaje de bienvenida"
    end

    test "handles translation errors" do
      content = "hello = Hello"

      expect_translate_error("Hello", "en", "es", :api_error)

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

      expect_translate("Hello, {$name}!", "en", "fr", "Bonjour, {$name}!")
      expect_translate("Goodbye", "en", "fr", "Au revoir")

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

      expect_translate("Third", "en", "es", "Tercero")
      expect_translate("First", "en", "es", "Primero")
      expect_translate("Second", "en", "es", "Segundo")

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

      expect_translate("Home", "en", "es", "Inicio")
      expect_translate("About Us", "en", "es", "Acerca de")
      expect_translate("Contact", "en", "es", "Contacto")
      expect_translate("Welcome to { $appName }!", "en", "es", "¡Bienvenido a { $appName }!")
      expect_translate("Welcome message", "en", "es", "Mensaje de bienvenida")
      expect_translate("Hello, { $userName }!", "en", "es", "¡Hola, { $userName }!")

      assert {:ok, result} = FtlHandler.translate(content, "en", "es")

      assert result =~ "## Main Navigation"
      assert result =~ "nav-home = Inicio"
      assert result =~ "## Messages"
      assert result =~ "# Welcome message shown on homepage"
      assert result =~ "welcome-message = ¡Bienvenido a { $appName }!"
      assert result =~ "    .aria-label = Mensaje de bienvenida"
    end
  end
end
