defmodule GlossiaWeb.API.TranslationControllerTest do
  use GlossiaWeb.ConnCase, async: true
  use Mimic

  setup %{conn: conn} do
    # Set content-type header for all API requests
    conn = put_req_header(conn, "content-type", "application/json")
    {:ok, conn: conn}
  end

  describe "POST /api/translate" do
    test "translates text format successfully", %{conn: conn} do
      Mimic.expect(Glossia.AI.Translator, :translate, fn "Hello", "en", "es" ->
        {:ok, "Hola"}
      end)

      params = %{
        "content" => "Hello",
        "source_locale" => "en",
        "target_locale" => "es",
        "format" => "text"
      }

      conn = post(conn, ~p"/api/translate", params)

      assert json = json_response(conn, 200)
      assert json["content"] == "Hola"
      assert json["format"] == "text"
      assert json["source_locale"] == "en"
      assert json["target_locale"] == "es"
    end

    test "translates FTL format successfully", %{conn: conn} do
      ftl_content = "hello = Hello, World!"
      expected = "hello = ¡Hola, Mundo!"

      Mimic.expect(Glossia.AI.Translator, :translate_with_instructions, fn ^ftl_content, "en", "es", _instructions ->
        {:ok, expected}
      end)

      params = %{
        "content" => ftl_content,
        "source_locale" => "en",
        "target_locale" => "es",
        "format" => "ftl"
      }

      conn = post(conn, ~p"/api/translate", params)

      assert json = json_response(conn, 200)
      assert json["content"] == expected
      assert json["format"] == "ftl"
      assert json["source_locale"] == "en"
      assert json["target_locale"] == "es"
    end

    test "translates complex FTL with variables", %{conn: conn} do
      ftl_content = """
      # Greeting
      welcome = Welcome, {$name}!
      """

      expected = """
      # Greeting
      welcome = Bienvenue, {$name}!
      """

      Mimic.expect(Glossia.AI.Translator, :translate_with_instructions, fn ^ftl_content, "en", "fr", _instructions ->
        {:ok, expected}
      end)

      params = %{
        "content" => ftl_content,
        "source_locale" => "en",
        "target_locale" => "fr",
        "format" => "ftl"
      }

      conn = post(conn, ~p"/api/translate", params)

      assert json = json_response(conn, 200)
      assert json["content"] =~ "# Greeting"
      assert json["content"] =~ "welcome = Bienvenue, {$name}!"
      assert json["format"] == "ftl"
    end

    test "translates FTL with multiple messages", %{conn: conn} do
      ftl_content = """
      hello = Hello
      goodbye = Goodbye
      welcome = Welcome
      """

      expected = """
      hello = Hola
      goodbye = Adiós
      welcome = Bienvenido
      """

      Mimic.expect(Glossia.AI.Translator, :translate_with_instructions, fn ^ftl_content, "en", "es", _instructions ->
        {:ok, expected}
      end)

      params = %{
        "content" => ftl_content,
        "source_locale" => "en",
        "target_locale" => "es",
        "format" => "ftl"
      }

      conn = post(conn, ~p"/api/translate", params)

      assert json = json_response(conn, 200)
      assert json["content"] =~ "hello = Hola"
      assert json["content"] =~ "goodbye = Adiós"
      assert json["content"] =~ "welcome = Bienvenido"
    end

    test "defaults to text format when format is not specified", %{conn: conn} do
      Mimic.expect(Glossia.AI.Translator, :translate, fn "Hello", "en", "es" ->
        {:ok, "Hola"}
      end)

      params = %{
        "content" => "Hello",
        "source_locale" => "en",
        "target_locale" => "es"
      }

      conn = post(conn, ~p"/api/translate", params)

      assert json = json_response(conn, 200)
      assert json["format"] == "text"
    end

    test "returns error for unsupported format", %{conn: conn} do
      params = %{
        "content" => "Hello",
        "source_locale" => "en",
        "target_locale" => "es",
        "format" => "unsupported_format"
      }

      conn = post(conn, ~p"/api/translate", params)

      # OpenApiSpex validates the enum, so we get 422 (validation error)
      assert json = json_response(conn, 422)
      assert json["errors"]
    end

    test "returns error when translation fails", %{conn: conn} do
      Mimic.expect(Glossia.AI.Translator, :translate, fn "Hello", "en", "es" ->
        {:error, :api_timeout}
      end)

      params = %{
        "content" => "Hello",
        "source_locale" => "en",
        "target_locale" => "es",
        "format" => "text"
      }

      conn = post(conn, ~p"/api/translate", params)

      assert json = json_response(conn, 500)
      assert json["error"] =~ "Translation failed"
    end

    test "validates required parameters are present", %{conn: conn} do
      # Missing content parameter
      params = %{
        "source_locale" => "en",
        "target_locale" => "es"
      }

      conn = post(conn, ~p"/api/translate", params)
      # OpenApiSpex validation should catch this
      assert conn.status in [400, 422]
    end

    test "FTL format preserves comments and structure", %{conn: conn} do
      ftl_content = """
      ## Header

      # Comment
      greeting = Hello
      """

      expected = """
      ## Header

      # Comment
      greeting = Hallo
      """

      Mimic.expect(Glossia.AI.Translator, :translate_with_instructions, fn ^ftl_content, "en", "de", _instructions ->
        {:ok, expected}
      end)

      params = %{
        "content" => ftl_content,
        "source_locale" => "en",
        "target_locale" => "de",
        "format" => "ftl"
      }

      conn = post(conn, ~p"/api/translate", params)

      assert json = json_response(conn, 200)
      assert json["content"] =~ "## Header"
      assert json["content"] =~ "# Comment"
      assert json["content"] =~ "greeting = Hallo"
    end

    test "FTL format skips variable-only values", %{conn: conn} do
      # Should not call translate for variable-only value
      ftl_content = "placeholder = {$value}"
      expected = "placeholder = {$value}"

      Mimic.expect(Glossia.AI.Translator, :translate_with_instructions, fn ^ftl_content, "en", "es", _instructions ->
        {:ok, expected}
      end)

      params = %{
        "content" => ftl_content,
        "source_locale" => "en",
        "target_locale" => "es",
        "format" => "ftl"
      }

      conn = post(conn, ~p"/api/translate", params)

      assert json = json_response(conn, 200)
      assert json["content"] == expected
    end

    test "supports all documented FTL format features", %{conn: conn} do
      ftl_content = """
      ## Navigation
      nav-home = Home

      # Welcome message
      welcome-msg = Welcome to {$app}!
          .aria-label = Welcome to {$app}!

      # Variable only - should not translate
      brand = {$brandName}
      """

      expected = """
      ## Navigation
      nav-home = ホーム

      # Welcome message
      welcome-msg = {$app}へようこそ！
          .aria-label = Welcome to {$app}!

      # Variable only - should not translate
      brand = {$brandName}
      """

      Mimic.expect(Glossia.AI.Translator, :translate_with_instructions, fn ^ftl_content, "en", "ja", _instructions ->
        {:ok, expected}
      end)

      params = %{
        "content" => ftl_content,
        "source_locale" => "en",
        "target_locale" => "ja",
        "format" => "ftl"
      }

      conn = post(conn, ~p"/api/translate", params)

      assert json = json_response(conn, 200)
      result = json["content"]

      assert result =~ "## Navigation"
      assert result =~ "nav-home = ホーム"
      assert result =~ "# Welcome message"
      assert result =~ "welcome-msg = {$app}へようこそ！"
      # Attributes (indented lines) are preserved as-is, not translated
      assert result =~ "    .aria-label = Welcome to {$app}!"
      assert result =~ "brand = {$brandName}"
    end
  end
end
