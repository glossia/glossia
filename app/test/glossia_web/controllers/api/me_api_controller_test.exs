defmodule GlossiaWeb.Api.MeApiControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.Accounts
  alias Glossia.Repo
  alias Glossia.TestHelpers

  setup do
    %{
      actor: TestHelpers.create_user("me-fluent@test.com", "me-fluent"),
      other: TestHelpers.create_user("other-me-fluent@test.com", "other-me-fluent")
    }
  end

  test "GET returns explicit fluency only for the authenticated actor", context do
    %{conn: conn, actor: actor, other: other} = context
    {:ok, actor} = Accounts.update_user_locale(actor, "es")
    {:ok, _} = Accounts.update_user_fluent_languages(other, ["ar"])

    body =
      conn
      |> TestHelpers.authenticate(actor, ["user:read"])
      |> get(~p"/api/me")
      |> json_response(200)

    assert body == profile(actor, [])

    {:ok, actor} = Accounts.update_user_fluent_languages(actor, ["HE", "zh-hant"])

    assert conn
           |> TestHelpers.authenticate(actor, ["user:read"])
           |> get(~p"/api/me")
           |> json_response(200) == profile(actor, ["he", "zh-Hant"])
  end

  test "read and write scopes are separate and both endpoints require authentication", context do
    %{conn: conn, actor: actor} = context
    assert conn |> get(~p"/api/me") |> json_response(401)

    assert conn
           |> put(~p"/api/me/fluent-languages", %{fluent_languages: ["ar"]})
           |> json_response(401)

    for scopes <- [[], ["user:write"]] do
      response = conn |> TestHelpers.authenticate(actor, scopes) |> get(~p"/api/me")
      assert json_response(response, 403)["required_scope"] == "user:read"
    end

    for scopes <- [[], ["user:read"]] do
      response =
        conn
        |> TestHelpers.authenticate(actor, scopes)
        |> put(~p"/api/me/fluent-languages", %{fluent_languages: ["ar"]})

      assert json_response(response, 403)["required_scope"] == "user:write"
      assert [header] = get_resp_header(response, "www-authenticate")
      assert header =~ "user:write"
    end

    assert Repo.reload!(actor).fluent_languages == []
  end

  test "write-only tokens can replace, repeat and clear with the same profile shape as GET",
       context do
    %{conn: conn, actor: actor, other: other} = context
    auth = TestHelpers.authenticate(conn, actor, ["user:write"])
    tags = ["AR", "he", "ar", "ZH-hant-tw", "pt-br", "sr-LATN-rs", "es-419"]
    expected = ["ar", "he", "zh-Hant-TW", "pt-BR", "sr-Latn-RS", "es-419"]

    for _ <- 1..2 do
      assert auth
             |> put(~p"/api/me/fluent-languages", %{fluent_languages: tags})
             |> json_response(200) == profile(actor, expected)

      assert Repo.reload!(actor).fluent_languages == expected
    end

    assert conn
           |> TestHelpers.authenticate(actor, ["user:read"])
           |> get(~p"/api/me")
           |> json_response(200) == profile(actor, expected)

    for _ <- 1..2 do
      assert auth
             |> put(~p"/api/me/fluent-languages", %{fluent_languages: []})
             |> json_response(200) == profile(actor, [])
    end

    assert Repo.reload!(actor).fluent_languages == []
    assert Repo.reload!(other).fluent_languages == []
  end

  test "invalid payloads and unrelated body fields return 422 without changing either user",
       context do
    %{conn: conn, actor: actor, other: other} = context
    {:ok, _} = Accounts.update_user_fluent_languages(actor, ["ar"])
    {:ok, _} = Accounts.update_user_fluent_languages(other, ["he"])
    auth = TestHelpers.authenticate(conn, actor, ["user:write"])

    for body <- [
          %{},
          %{user: %{fluent_languages: ["en"]}},
          %{fluent_languages: nil},
          %{fluent_languages: "en"},
          %{fluent_languages: 1},
          %{fluent_languages: true},
          %{fluent_languages: %{"0" => "en"}},
          %{fluent_languages: [nil]},
          %{fluent_languages: [1]},
          %{fluent_languages: [%{}]},
          %{fluent_languages: [""]},
          %{fluent_languages: ["ar", "zz"]},
          %{fluent_languages: ["en-invented"]},
          %{fluent_languages: ["en-XX"]},
          %{fluent_languages: ["en-Zzzz"]},
          %{fluent_languages: List.duplicate("en", 51)},
          %{fluent_languages: ["en"], id: other.id},
          %{fluent_languages: ["en"], user_id: other.id},
          %{fluent_languages: ["en"], account_id: other.account_id},
          %{fluent_languages: ["en"], locale: "es"},
          %{fluent_languages: ["en"], name: "Not mutable here"},
          %{fluent_languages: ["en"], super_admin: true}
        ] do
      response = auth |> put(~p"/api/me/fluent-languages", body) |> json_response(422)
      assert response["errors"]["fluent_languages"] != []
      assert Repo.reload!(actor).fluent_languages == ["ar"]
      assert Repo.reload!(other).fluent_languages == ["he"]
    end

    for body <- [[], ["en"], "en", nil] do
      assert auth
             |> put(~p"/api/me/fluent-languages", Jason.encode!(body))
             |> json_response(422)
    end

    assert auth
           |> put(~p"/api/me/fluent-languages?#{%{fluent_languages: ["en"]}}", %{})
           |> json_response(422)

    assert Repo.reload!(actor).fluent_languages == ["ar"]
    assert Repo.reload!(other).fluent_languages == ["he"]
    refute Repo.reload!(actor).super_admin
  end

  test "a different actor can only replace their own languages", context do
    %{conn: conn, actor: actor, other: other} = context
    {:ok, _} = Accounts.update_user_fluent_languages(actor, ["ar"])

    assert conn
           |> TestHelpers.authenticate(other, ["user:write"])
           |> put(~p"/api/me/fluent-languages", %{fluent_languages: ["HE"]})
           |> json_response(200) == profile(other, ["he"])

    assert Repo.reload!(actor).fluent_languages == ["ar"]
    assert Repo.reload!(other).fluent_languages == ["he"]
  end

  defp profile(user, languages) do
    %{
      "user" => %{
        "id" => user.id,
        "email" => user.email,
        "name" => user.name,
        "handle" => user.account.handle,
        "fluent_languages" => languages
      },
      "server_version" => to_string(Application.spec(:glossia, :vsn))
    }
  end
end
