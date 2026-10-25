defmodule GlossiaWeb.MobileOpenApiSpecTest do
  use ExUnit.Case, async: true

  test "all mobile operations publish OAuth scopes, request and response schemas" do
    spec = GlossiaWeb.OpenApiSpec.spec()
    paths = spec["paths"]
    schemas = spec["components"]["schemas"]

    scopes =
      spec["components"]["securitySchemes"]["oauth2"]["flows"]["authorizationCode"]["scopes"]

    for {path, method, scope, schema, status} <- [
          {"/api/me", "get", "user:read", "MobileProfile", "200"},
          {"/api/{handle}/projects/{project}/translations", "get", "translation:read",
           "MobileTranslations", "200"},
          {"/api/{handle}/projects/{project}/translations/{id}", "get", "translation:read",
           "MobileTranslation", "200"},
          {"/api/{handle}/projects/{project}/analytics", "get", "analytics:read",
           "MobileAnalytics", "200"},
          {"/api/{handle}/projects/{project}/toki/conversations", "get", "toki:read",
           "TokiConversations", "200"},
          {"/api/{handle}/projects/{project}/toki/conversations", "post", "toki:write",
           "TokiDetail", "201"},
          {"/api/{handle}/projects/{project}/toki/conversations/{id}", "get", "toki:read",
           "TokiDetail", "200"},
          {"/api/{handle}/projects/{project}/toki/conversations/{id}/messages", "post",
           "toki:write", "TokiDetail", "202"}
        ] do
      operation = paths[path][method]
      assert operation["security"] == [%{"oauth2" => [scope]}]
      assert Map.has_key?(scopes, scope)

      assert operation["responses"][status]["content"]["application/json"]["schema"]["$ref"] ==
               "#/components/schemas/#{schema}"

      assert Map.has_key?(schemas, schema)
    end

    assert schemas["TokiDetail"]["properties"]["messages"]["maxItems"] == 100
    assert schemas["TokiMessageRequest"]["properties"]["content"]["maxLength"] == 8_000
    assert schemas["TokiCreateRequest"]["required"] == ["id"]

    assert schemas["TokiCreateRequest"]["properties"]["translation_session_id"]["format"] ==
             "uuid"

    assert schemas["TokiConversation"]["properties"]["translation_session_id"]["type"] == [
             "string",
             "null"
           ]

    assert "translation_session_id" in schemas["TokiConversation"]["required"]

    list_fields = schemas["MobileTranslations"]["properties"]["sessions"]["items"]["properties"]
    detail_fields = schemas["MobileTranslation"]["properties"]["session"]["properties"]
    assert Map.delete(detail_fields, "commit_sha") == list_fields
  end
end
