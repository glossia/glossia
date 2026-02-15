defmodule GlossiaWeb.Api.VoiceApiControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.Voices
  alias GlossiaWeb.ApiTestHelpers

  @read_scopes ~w(voice:read)
  @write_scopes ~w(voice:write)
  @read_write_scopes ~w(voice:read voice:write)

  setup do
    owner = ApiTestHelpers.create_user("voice-owner@test.com", "voice-owner")
    outsider = ApiTestHelpers.create_user("voice-outsider@test.com", "voice-outsider")

    no_access =
      ApiTestHelpers.create_user("voice-noaccess@test.com", "voice-noaccess", has_access: false)

    {:ok, %{voice: voice}} =
      Voices.create_voice(owner.account, %{tone: "formal", formality: "neutral"}, owner)

    %{owner: owner, outsider: outsider, no_access: no_access, voice: voice}
  end

  describe "GET /api/:handle/voice" do
    test "returns the latest voice when authorized", %{conn: conn, owner: owner} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(owner, @read_scopes)
        |> get("/api/#{owner.account.handle}/voice")

      assert %{"version" => 1, "tone" => "formal", "formality" => "neutral"} =
               json_response(conn, 200)
    end

    test "returns 400 for invalid version param", %{conn: conn, owner: owner} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(owner, @read_scopes)
        |> get("/api/#{owner.account.handle}/voice?version=not-an-int")

      assert %{"error" => "invalid_version"} = json_response(conn, 400)
    end

    test "returns 403 when missing required scope", %{conn: conn, owner: owner} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(owner, [])
        |> get("/api/#{owner.account.handle}/voice")

      assert %{"error" => "insufficient_scope", "required_scope" => "voice:read"} =
               json_response(conn, 403)
    end

    test "returns 403 for a different account", %{conn: conn, owner: owner, outsider: outsider} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(outsider, @read_scopes)
        |> get("/api/#{owner.account.handle}/voice")

      assert %{"error" => "not_authorized"} = json_response(conn, 403)
    end
  end

  describe "POST /api/:handle/voice" do
    test "creates a new voice version when authorized", %{conn: conn, owner: owner} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(owner, @write_scopes)
        |> post("/api/#{owner.account.handle}/voice", %{
          tone: "casual",
          formality: "informal",
          change_note: "Loosen tone for marketing pages"
        })

      assert %{"version" => 2, "tone" => "casual", "formality" => "informal"} =
               json_response(conn, 201)
    end

    test "returns 403 for users without access", %{conn: conn, no_access: no_access} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(no_access, @write_scopes)
        |> post("/api/#{no_access.account.handle}/voice", %{
          tone: "casual",
          formality: "informal"
        })

      assert %{"error" => "not_authorized"} = json_response(conn, 403)
    end
  end

  describe "GET /api/:handle/voice/history" do
    test "returns voice versions when authorized", %{conn: conn, owner: owner} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(owner, @read_write_scopes)
        |> get("/api/#{owner.account.handle}/voice/history")

      assert %{"versions" => versions} = json_response(conn, 200)
      assert Enum.any?(versions, &(&1["version"] == 1))
    end
  end
end
