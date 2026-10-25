defmodule GlossiaWeb.MobileOpenApiSpec do
  @moduledoc false

  def paths do
    project = "/api/{handle}/projects/{project}"
    conversations = project <> "/toki/conversations"

    %{
      "/api/native/themes" => %{
        "get" => %{
          "operationId" => "nativeThemes",
          "summary" => "Get the native appearance catalog",
          "description" =>
            "Public, instance-wide appearance metadata compiled from the canonical CSS tokens. No user data or authentication.",
          "tags" => ["Mobile"],
          "security" => [],
          "responses" => %{
            "200" =>
              response("NativeThemeCatalog", "Native appearance catalog")
              |> Map.put("headers", %{
                "Cache-Control" => %{
                  "schema" => %{"type" => "string", "const" => "public, max-age=300"}
                }
              })
          }
        }
      },
      "/api/me" => %{
        "get" => operation("currentUser", "user:read", "MobileProfile", [], "200")
      },
      (project <> "/translations") => %{
        "parameters" => project_parameters(),
        "get" =>
          operation(
            "projectTranslations",
            "translation:read",
            "MobileTranslations",
            pagination(),
            "200"
          )
      },
      (project <> "/translations/{id}") => %{
        "parameters" => project_parameters() ++ [conversation_parameter()],
        "get" =>
          operation("projectTranslation", "translation:read", "MobileTranslation", [], "200")
          |> Map.put(
            "description",
            "Exact project-scoped UUID lookup, independent of list pagination. Returns session-summary-level metadata, not segment text. Malformed, missing and foreign-project IDs return 404."
          )
      },
      (project <> "/analytics") => %{
        "parameters" => project_parameters(),
        "get" =>
          operation(
            "projectAnalytics",
            "analytics:read",
            "MobileAnalytics",
            [integer_parameter("days", 30, 1, 365)],
            "200"
          )
          |> put_in(["responses", "503"], %{"description" => "Analytics storage unavailable"})
      },
      conversations => %{
        "parameters" => project_parameters(),
        "get" =>
          operation(
            "listTokiConversations",
            "toki:read",
            "TokiConversations",
            pagination(),
            "200"
          )
          |> Map.put(
            "description",
            "Private histories for the actor and project. Source-linked conversations require current translation:read scope and policy permission and a source still in the same project/account; otherwise they are omitted before pagination and counts."
          ),
        "post" =>
          operation("createTokiConversation", "toki:write", "TokiDetail", [], "201")
          |> Map.put("requestBody", request_body("TokiCreateRequest"))
          |> Map.put(
            "description",
            "Create an idle private conversation without sending a message or starting inference. Optional translation_session_id additionally requires translation:read scope and policy permission. The immutable origin must match on UUID replay or returns 409 id_conflict. Missing/foreign source returns 404. Source-linked detail, replay and sends fail closed without current translation:read; such histories are omitted from lists, including counts. Deleted sources fail closed too."
          )
      },
      (conversations <> "/{id}") => %{
        "parameters" => project_parameters() ++ [conversation_parameter()],
        "get" =>
          operation("getTokiConversation", "toki:read", "TokiDetail", [], "200")
          |> Map.put(
            "description",
            "Source-linked detail fails closed with 403 without current translation:read scope or policy permission, including all metadata and messages. A deleted or moved source returns 404. The reference alone grants no access."
          )
      },
      (conversations <> "/{id}/messages") => %{
        "parameters" => project_parameters() ++ [conversation_parameter()],
        "post" =>
          operation("sendTokiMessage", "toki:write", "TokiDetail", [], "202")
          |> Map.put("requestBody", request_body("TokiMessageRequest"))
          |> Map.put(
            "description",
            "Atomically persist a user message and enqueue inference. Poll the conversation while queued/running. " <>
              "Replaying the same UUID and content never re-enqueues inference. Returns 200 for a settled replay. " <>
              "A UUID reused with different content or in another conversation returns 409. " <>
              "All histories are private to the actor and project, including for administrators. " <>
              "Source-linked conversations additionally require current translation:read. Body fields cannot replace the persisted origin."
          )
          |> put_in(["responses", "200"], response("TokiDetail", "Settled replay"))
      }
    }
  end

  def schemas do
    %{
      "NativeThemeCatalog" =>
        object(%{
          "schema_version" => %{"type" => "integer", "const" => 1},
          "revision" => %{
            "type" => "string",
            "minLength" => 1,
            "maxLength" => 128,
            "pattern" => "\\S",
            "description" => "Deterministic content revision, changed when the catalog changes"
          },
          "default_theme_id" => %{"type" => "string", "const" => "glossia"},
          "themes" => %{
            "type" => "array",
            "minItems" => 1,
            "items" => ref("NativeTheme")
          }
        }),
      "NativeTheme" =>
        object(%{
          "id" => %{"type" => "string", "const" => "glossia"},
          "name" => %{"type" => "string", "minLength" => 1, "maxLength" => 80},
          "description" => %{"type" => "string", "minLength" => 1, "maxLength" => 160},
          "typography" => %{"type" => "string", "const" => "standard"},
          "button_radius" => %{"type" => "number", "minimum" => 0, "maximum" => 24},
          "card_radius" => %{"type" => "number", "minimum" => 0, "maximum" => 32},
          "light" => ref("NativeThemePalette"),
          "dark" => ref("NativeThemePalette")
        }),
      "NativeThemePalette" =>
        object(
          Map.new(
            ~w(background surface subtle text secondary_text border accent on_accent tint),
            &{&1, %{"type" => "string", "pattern" => "^#[0-9A-F]{6}$"}}
          )
        ),
      "MobileProfile" =>
        object(%{
          "user" =>
            object(%{
              "id" => uuid(),
              "name" => nullable_string(),
              "email" => string(),
              "handle" => string()
            }),
          "server_version" => string()
        }),
      "MobileTranslations" =>
        object(%{
          "sessions" => array(object(session_properties())),
          "meta" => ref("PaginationMeta")
        }),
      "MobileTranslation" =>
        object(%{
          "session" => object(Map.put(session_properties(), "commit_sha", nullable_string()))
        }),
      "MobileAnalytics" =>
        object(%{
          "summary" =>
            object(%{
              "pageviews" => integer(),
              "unique_visitors" => integer(),
              "locale_gap_visits" => integer(),
              "top_country" => string(),
              "top_browser_language" => string()
            }),
          "top_pages" => array(object(%{"pathname" => string(), "pageviews" => integer()})),
          "days" => %{"type" => "integer", "minimum" => 1, "maximum" => 365}
        }),
      "TokiConversation" =>
        object(%{
          "id" => uuid(),
          "translation_session_id" =>
            Map.put(
              nullable_uuid(),
              "description",
              "Immutable session-summary-level origin, or null"
            ),
          "title" => string(),
          "status" => %{"type" => "string", "enum" => ~w(queued running completed failed)},
          "updated_at" => timestamp(),
          "error" =>
            Map.put(
              nullable_string(),
              "description",
              "Safe failure code; never provider credentials or raw errors"
            )
        }),
      "TokiConversations" =>
        object(%{
          "conversations" => array(ref("TokiConversation")),
          "meta" => ref("PaginationMeta")
        }),
      "TokiDetail" =>
        object(%{
          "conversation" => ref("TokiConversation"),
          "messages" => %{
            "type" => "array",
            "maxItems" => 100,
            "description" =>
              "Complete bounded history, chronological by inserted_at and UUID. No history pagination is needed.",
            "items" =>
              object(%{
                "id" => uuid(),
                "role" => %{"type" => "string", "enum" => ~w(user assistant)},
                "content" => string(),
                "inserted_at" => timestamp()
              })
          }
        }),
      "TokiCreateRequest" =>
        object(%{"id" => uuid(), "translation_session_id" => nullable_uuid()})
        |> Map.put("required", ["id"]),
      "TokiMessageRequest" =>
        object(%{
          "id" => uuid(),
          "content" => %{
            "type" => "string",
            "minLength" => 1,
            "maxLength" => 8_000,
            "description" =>
              "Non-blank text, at most 32,000 UTF-8 bytes. Other fields cannot change role, owner or status."
          }
        })
    }
  end

  defp operation(id, scope, schema, parameters, success) do
    %{
      "operationId" => id,
      "summary" => id,
      "tags" => ["Mobile"],
      "security" => [%{"oauth2" => [scope]}],
      "parameters" => parameters,
      "responses" => %{
        success => response(schema, "Success"),
        "400" => %{"description" => "Invalid pagination or reporting window"},
        "401" => %{"description" => "Missing, expired or invalid bearer token"},
        "403" => %{"description" => "Insufficient token scope or project permission"},
        "404" => %{
          "description" =>
            "Unknown resource or private conversation owned by another actor/project"
        },
        "409" => %{
          "description" => "UUID conflict or conversation already processing another message"
        },
        "422" => %{
          "description" => "Invalid UUID, message content, or conversation/history limit reached"
        },
        "429" => %{
          "description" =>
            "API rate limit, 30 messages/hour per user per server, or five pending conversations per user"
        }
      }
    }
  end

  defp response(schema, description),
    do: %{
      "description" => description,
      "content" => %{"application/json" => %{"schema" => ref(schema)}}
    }

  defp session_properties do
    %{
      "id" => uuid(),
      "status" => %{"type" => "string", "enum" => ~w(pending running completed failed cancelled)},
      "commit_message" => nullable_string(),
      "source_language" => nullable_string(),
      "target_languages" => array(string()),
      "translated_content_count" => integer(),
      "inserted_at" => timestamp(),
      "summary" => nullable_string()
    }
  end

  defp request_body(schema),
    do: %{
      "required" => true,
      "content" => %{"application/json" => %{"schema" => ref(schema)}}
    }

  defp project_parameters do
    for name <- ["handle", "project"],
        do: %{"name" => name, "in" => "path", "required" => true, "schema" => string()}
  end

  defp conversation_parameter,
    do: %{"name" => "id", "in" => "path", "required" => true, "schema" => uuid()}

  defp pagination,
    do: [integer_parameter("page", 1, 1, 10_000), integer_parameter("page_size", 20, 1, 50)]

  defp integer_parameter(name, default, min, max),
    do: %{
      "name" => name,
      "in" => "query",
      "schema" => %{"type" => "integer", "default" => default, "minimum" => min, "maximum" => max}
    }

  defp object(properties),
    do: %{"type" => "object", "properties" => properties, "required" => Map.keys(properties)}

  defp array(items), do: %{"type" => "array", "items" => items}
  defp ref(name), do: %{"$ref" => "#/components/schemas/" <> name}
  defp string, do: %{"type" => "string"}
  defp nullable_string, do: %{"type" => ["string", "null"]}
  defp integer, do: %{"type" => "integer", "minimum" => 0}
  defp uuid, do: %{"type" => "string", "format" => "uuid"}
  defp nullable_uuid, do: %{"type" => ["string", "null"], "format" => "uuid"}
  defp timestamp, do: %{"type" => "string", "format" => "date-time"}
end
