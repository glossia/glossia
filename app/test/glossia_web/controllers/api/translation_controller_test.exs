defmodule GlossiaWeb.Api.TranslationControllerTest do
  use GlossiaWeb.ConnCase, async: true
  use Mimic

  alias Glossia.TestHelpers
  alias Glossia.Translations

  @scopes ~w(translation:write)

  setup do
    owner = TestHelpers.create_user("translate-api-owner@test.com", "translate-api-owner")

    outsider =
      TestHelpers.create_user("translate-api-outsider@test.com", "translate-api-outsider")

    %{owner: owner, outsider: outsider}
  end

  defp payload do
    %{
      "model" => "translator",
      "format" => "markdown",
      "source_language" => "English",
      "language" => "Spanish",
      "locale" => "es",
      "source_content" => "Hello"
    }
  end

  defp translate_path(user), do: "/api/#{user.account.handle}/translate"

  describe "POST /api/:handle/translate authorization" do
    test "403 when missing the translation:write scope", %{conn: conn, owner: owner} do
      conn =
        conn
        |> TestHelpers.authenticate(owner, [])
        |> post(translate_path(owner), payload())

      assert %{"error" => "insufficient_scope", "required_scope" => "translation:write"} =
               json_response(conn, 403)
    end

    test "403 for a different account", %{conn: conn, owner: owner, outsider: outsider} do
      conn =
        conn
        |> TestHelpers.authenticate(outsider, @scopes)
        |> post(translate_path(owner), payload())

      assert json_response(conn, 403)
    end

    test "404 for an unknown account", %{conn: conn, owner: owner} do
      conn =
        conn
        |> TestHelpers.authenticate(owner, @scopes)
        |> post("/api/does-not-exist/translate", payload())

      assert %{"error" => %{"message" => "account not found"}} = json_response(conn, 404)
    end
  end

  describe "POST /api/:handle/translate results" do
    test "200 returns the translated content and resolved model", %{conn: conn, owner: owner} do
      Mimic.expect(Translations, :translate, fn account, params ->
        assert account.id == owner.account.id
        assert params["locale"] == "es"

        {:ok,
         %{
           text: "Hola",
           model: "anthropic/claude",
           model_handle: "translator",
           provider: "anthropic"
         }}
      end)

      conn =
        conn
        |> TestHelpers.authenticate(owner, @scopes)
        |> post(translate_path(owner), payload())

      assert %{
               "text" => "Hola",
               "model" => "anthropic/claude",
               "model_handle" => "translator",
               "provider" => "anthropic"
             } = json_response(conn, 200)
    end

    test "422 for a missing field", %{conn: conn, owner: owner} do
      Mimic.stub(Translations, :translate, fn _account, _params ->
        {:error, {:missing_field, "locale"}}
      end)

      conn =
        conn
        |> TestHelpers.authenticate(owner, @scopes)
        |> post(translate_path(owner), payload())

      assert %{"error" => %{"message" => "missing required field: locale"}} =
               json_response(conn, 422)
    end

    test "404 when the model is not configured", %{conn: conn, owner: owner} do
      Mimic.stub(Translations, :translate, fn _account, _params ->
        {:error, {:model_not_found, "translator"}}
      end)

      conn =
        conn
        |> TestHelpers.authenticate(owner, @scopes)
        |> post(translate_path(owner), payload())

      assert %{"error" => %{"message" => message}} = json_response(conn, 404)
      assert message =~ "not found"
    end

    test "502 when the model call fails", %{conn: conn, owner: owner} do
      Mimic.stub(Translations, :translate, fn _account, _params ->
        {:error, {:llm_failed, "boom"}}
      end)

      conn =
        conn
        |> TestHelpers.authenticate(owner, @scopes)
        |> post(translate_path(owner), payload())

      assert json_response(conn, 502)
    end
  end
end
