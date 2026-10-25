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
          {"/api/me/fluent-languages", "put", "user:write", "MobileProfile", "200"},
          {"/api/{handle}/projects/{project}/translations", "get", "translation:read",
           "MobileTranslations", "200"},
          {"/api/{handle}/projects/{project}/translations/{id}", "get", "translation:read",
           "MobileTranslation", "200"},
          {"/api/{handle}/projects/{project}/translations/{id}/reviews", "get",
           "translation:read", "LinguisticReviews", "200"},
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

    answer =
      paths["/api/{handle}/projects/{project}/translations/{id}/reviews/{review_id}/answer"][
        "post"
      ]

    assert answer["security"] == [%{"oauth2" => ~w(translation:read translation:write)}]
    assert schemas["LinguisticReviewRequest"]["required"] == ["answer", "resolution_message_id"]
    assert schemas["LinguisticReview"]["properties"]["resumed_session_id"]["format"] == "uuid"

    for {path, methods} <- [
          {"/api/me/push-devices/capabilities", ["get"]},
          {"/api/me/push-devices/{installation_id}", ["put", "delete"]}
        ],
        method <- methods do
      assert paths[path][method]["security"] == [%{"oauth2" => []}]
    end

    assert schemas["PushDeviceRequest"]["additionalProperties"] == false
  end

  test "analytics publishes the real traffic series and bucket-local visitor semantics" do
    schema = GlossiaWeb.OpenApiSpec.spec()["components"]["schemas"]["MobileAnalytics"]
    assert "traffic" in schema["required"]
    traffic = schema["properties"]["traffic"]
    assert Enum.sort(traffic["required"]) == ~w(granularity points)
    assert traffic["properties"]["granularity"]["enum"] == ~w(hour day month)
    points = traffic["properties"]["points"]
    assert points["type"] == "array"
    assert points["description"] =~ "Empty when there are no events"
    assert points["description"] =~ "zero-count buckets"
    point = points["items"]
    assert Enum.sort(point["required"]) == ~w(bucket pageviews unique_visitors)
    assert point["properties"]["bucket"]["format"] == "date-time"
    assert point["properties"]["bucket"]["description"] =~ "UTC"

    for metric <- ~w(pageviews unique_visitors) do
      assert point["properties"][metric]["type"] == "integer"
      assert point["properties"][metric]["minimum"] == 0
    end

    assert point["properties"]["unique_visitors"]["description"] =~ "not additive"
  end

  test "translation detail documents bounded progress without widening session fields" do
    schemas = GlossiaWeb.OpenApiSpec.spec()["components"]["schemas"]
    detail = schemas["MobileTranslation"]
    assert Enum.sort(detail["required"]) == ~w(progress session)

    assert detail["properties"]["progress"]["$ref"] ==
             "#/components/schemas/MobileTranslationProgress"

    progress = schemas["MobileTranslationProgress"]
    assert Enum.sort(progress["required"]) == ~w(items omitted_items seq summary)
    assert progress["properties"]["items"]["maxItems"] == 500
    assert progress["properties"]["seq"]["description"] =~ "Durable"
    item = schemas["MobileTranslationProgressItem"]
    assert Enum.sort(item["required"]) == ~w(file_ref index locale output_path status turns)

    assert item["properties"]["status"]["enum"] ==
             ~w(queued running done failed cancelled awaiting_input)

    refute Map.has_key?(item["properties"], "text")
    refute Map.has_key?(item["properties"], "reason")
    summary = schemas["MobileTranslationProgressSummary"]
    assert "assessed?" in summary["required"]
    assert "glossary" in summary["required"]
    assert "awaiting_input" in summary["required"]
  end
end
