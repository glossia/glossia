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
      Mimic.expect(Glossia.AI.Translator, :translate, fn "Hello, World!", "en", "es" ->
        {:ok, "¡Hola, Mundo!"}
      end)

      ftl_content = "hello = Hello, World!"

      params = %{
        "content" => ftl_content,
        "source_locale" => "en",
        "target_locale" => "es",
        "format" => "ftl"
      }

      conn = post(conn, ~p"/api/translate", params)

      assert json = json_response(conn, 200)
      assert json["content"] == "hello = ¡Hola, Mundo!"
      assert json["format"] == "ftl"
      assert json["source_locale"] == "en"
      assert json["target_locale"] == "es"
    end

    test "translates complex FTL with variables", %{conn: conn} do
      Mimic.expect(Glossia.AI.Translator, :translate, fn "Welcome, {$name}!", "en", "fr" ->
        {:ok, "Bienvenue, {$name}!"}
      end)

      ftl_content = """
      # Greeting
      welcome = Welcome, {$name}!
      """

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
      Mimic.expect(Glossia.AI.Translator, :translate, 3, fn text, "en", "es" ->
        case text do
          "Hello" -> {:ok, "Hola"}
          "Goodbye" -> {:ok, "Adiós"}
          "Welcome" -> {:ok, "Bienvenido"}
        end
      end)

      ftl_content = """
      hello = Hello
      goodbye = Goodbye
      welcome = Welcome
      """

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
      Mimic.expect(Glossia.AI.Translator, :translate, fn "Hello", "en", "de" ->
        {:ok, "Hallo"}
      end)

      ftl_content = """
      ## Header

      # Comment
      greeting = Hello
      """

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

      params = %{
        "content" => ftl_content,
        "source_locale" => "en",
        "target_locale" => "es",
        "format" => "ftl"
      }

      conn = post(conn, ~p"/api/translate", params)

      assert json = json_response(conn, 200)
      assert json["content"] == "placeholder = {$value}"
    end

    test "supports all documented FTL format features", %{conn: conn} do
      # "Welcome to {$app}!" appears twice (main message and aria-label)
      Mimic.stub(Glossia.AI.Translator, :translate, fn text, "en", "ja" ->
        case text do
          "Home" -> {:ok, "ホーム"}
          "Welcome to {$app}!" -> {:ok, "{$app}へようこそ！"}
        end
      end)

      ftl_content = """
      ## Navigation
      nav-home = Home

      # Welcome message
      welcome-msg = Welcome to {$app}!
          .aria-label = Welcome to {$app}!

      # Variable only - should not translate
      brand = {$brandName}
      """

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
      assert result =~ "    .aria-label = {$app}へようこそ！"
      assert result =~ "brand = {$brandName}"
    end
  end
end
