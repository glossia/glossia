defmodule GlossiaWeb.Api.GlossaryApiControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.Glossaries
  alias GlossiaWeb.ApiTestHelpers

  @read_scopes ~w(glossary:read)
  @write_scopes ~w(glossary:write)
  @read_write_scopes ~w(glossary:read glossary:write)

  setup do
    owner = ApiTestHelpers.create_user("glossary-owner@test.com", "glossary-owner")
    outsider = ApiTestHelpers.create_user("glossary-outsider@test.com", "glossary-outsider")

    no_access =
      ApiTestHelpers.create_user("glossary-noaccess@test.com", "glossary-noaccess",
        has_access: false
      )

    {:ok, %{glossary: glossary}} =
      Glossaries.create_glossary(
        owner.account,
        %{
          change_note: "Initial glossary",
          entries: [
            %{
              term: "project",
              definition: "A repo or app tracked by Glossia",
              case_sensitive: false,
              translations: [
                %{locale: "es", translation: "proyecto"},
                %{locale: "ja", translation: "\u30D7\u30ED\u30B8\u30A7\u30AF\u30C8"}
              ]
            },
            %{
              term: "API",
              definition: "Application Programming Interface",
              case_sensitive: true,
              translations: [
                %{locale: "es", translation: "API"}
              ]
            }
          ]
        },
        owner
      )

    %{owner: owner, outsider: outsider, no_access: no_access, glossary: glossary}
  end

  describe "GET /api/:handle/glossary" do
    test "returns the latest glossary when authorized", %{conn: conn, owner: owner} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(owner, @read_scopes)
        |> get("/api/#{owner.account.handle}/glossary")

      assert %{"version" => 1, "entries" => entries} = json_response(conn, 200)
      assert length(entries) == 2

      project_entry = Enum.find(entries, &(&1["term"] == "project"))
      assert project_entry["definition"] == "A repo or app tracked by Glossia"
      assert length(project_entry["translations"]) == 2
    end

    test "returns resolved glossary for a locale", %{conn: conn, owner: owner} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(owner, @read_scopes)
        |> get("/api/#{owner.account.handle}/glossary?locale=es")

      assert %{"version" => 1, "locale" => "es", "entries" => entries} =
               json_response(conn, 200)

      assert length(entries) == 2
      assert Enum.all?(entries, &(&1["translation"] != nil))
    end

    test "returns 400 for invalid version param", %{conn: conn, owner: owner} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(owner, @read_scopes)
        |> get("/api/#{owner.account.handle}/glossary?version=not-an-int")

      assert %{"error" => "invalid_version"} = json_response(conn, 400)
    end

    test "returns 403 when missing required scope", %{conn: conn, owner: owner} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(owner, [])
        |> get("/api/#{owner.account.handle}/glossary")

      assert %{"error" => "insufficient_scope", "required_scope" => "glossary:read"} =
               json_response(conn, 403)
    end

    test "returns 403 for a different account", %{conn: conn, owner: owner, outsider: outsider} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(outsider, @read_scopes)
        |> get("/api/#{owner.account.handle}/glossary")

      assert %{"error" => "not_authorized"} = json_response(conn, 403)
    end
  end

  describe "POST /api/:handle/glossary" do
    test "creates a new glossary version when authorized", %{conn: conn, owner: owner} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(owner, @write_scopes)
        |> post("/api/#{owner.account.handle}/glossary", %{
          change_note: "Add new term",
          entries: [
            %{
              term: "workspace",
              definition: "A logical container",
              translations: [%{locale: "de", translation: "Arbeitsbereich"}]
            }
          ]
        })

      assert %{"version" => 2, "entries" => [entry]} = json_response(conn, 201)
      assert entry["term"] == "workspace"
      assert length(entry["translations"]) == 1
    end

    test "returns 403 for users without access", %{conn: conn, no_access: no_access} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(no_access, @write_scopes)
        |> post("/api/#{no_access.account.handle}/glossary", %{
          entries: [%{term: "test"}]
        })

      assert %{"error" => "not_authorized"} = json_response(conn, 403)
    end
  end

  describe "GET /api/:handle/glossary/history" do
    test "returns glossary versions when authorized", %{conn: conn, owner: owner} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(owner, @read_write_scopes)
        |> get("/api/#{owner.account.handle}/glossary/history")

      assert %{"versions" => versions} = json_response(conn, 200)
      assert Enum.any?(versions, &(&1["version"] == 1))
    end
  end
end
