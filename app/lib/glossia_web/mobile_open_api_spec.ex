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
      "/api/me/fluent-languages" => %{
        "put" =>
          operation("updateFluentLanguages", "user:write", "MobileProfile", [], "200")
          |> Map.put("requestBody", request_body("FluentLanguagesRequest"))
          |> Map.put(
            "description",
            "Replace the authenticated user's fluent languages independently of the display language. Canonical CLDR-supported BCP47 tags, at most 50 submitted entries; duplicates collapse. An empty array clears fluency. Unrelated fields and invalid languages return 422."
          )
      },
      "/api/me/push-devices/capabilities" => %{
        "get" =>
          operation("pushCapabilities", "user:read", "PushCapabilities", [], "200")
          |> Map.put("security", [%{"oauth2" => []}])
          |> Map.put(
            "description",
            "Configured providers for an authenticated native PKCE client."
          )
      },
      "/api/me/push-devices/{installation_id}" => %{
        "parameters" => [
          %{"name" => "installation_id", "in" => "path", "required" => true, "schema" => uuid()}
        ],
        "put" =>
          operation("registerPushDevice", "user:read", "PushRegistration", [], "200")
          |> Map.put("security", [%{"oauth2" => []}])
          |> Map.put("requestBody", request_body("PushDeviceRequest"))
          |> Map.put(
            "description",
            "Opt-in registration bound to the current user and native PKCE OAuth client. Non-native credentials return 403. Retired IDs return 409; rotate the UUID. Missing provider returns 503. Responses are no-store."
          )
          |> put_in(["responses", "503"], %{"description" => "Provider unavailable"}),
        "delete" =>
          operation("unregisterPushDevice", "user:read", "PushDeletion", [], "200")
          |> Map.put("security", [%{"oauth2" => []}])
          |> Map.put(
            "description",
            "Idempotently retire this native installation, fencing delayed registrations. Available even when the provider is disabled."
          )
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
            "Exact project-scoped UUID lookup, independent of list pagination. Returns unchanged session metadata plus durable progress, per-file status and omitted_items. No raw output or reasoning. The same full projection is returned by translation:<UUID> joins and snapshot events on /native/socket/websocket?vsn=2.0.0. Malformed, missing and foreign-project IDs return 404."
          )
      },
      (project <> "/translations/{id}/reviews") => %{
        "parameters" => project_parameters() ++ [conversation_parameter()],
        "get" =>
          operation("translationReviews", "translation:read", "LinguisticReviews", [], "200")
          |> Map.put(
            "description",
            "Shared source-bound goals, each linked to one collaborative Toki conversation. At most 500 reviews, open goals first, then oldest first. Refresh after resolving to reveal any remaining goals."
          )
      },
      (project <> "/translations/{id}/reviews/{review_id}/answer") => %{
        "parameters" =>
          project_parameters() ++
            [
              conversation_parameter(),
              %{"name" => "review_id", "in" => "path", "required" => true, "schema" => uuid()}
            ],
        "post" =>
          operation(
            "answerTranslationReview",
            "translation:write",
            "LinguisticReviewAnswer",
            [],
            "200"
          )
          |> Map.put("security", [%{"oauth2" => ~w(translation:read translation:write)}])
          |> Map.put("requestBody", request_body("LinguisticReviewRequest"))
          |> Map.put(
            "description",
            "Explicitly approve a goal decision, binding resolution_message_id to the latest completed assistant reply (not the opening question). Busy conversations return 409 conversation_busy; changed/latest non-assistant messages return 409 resolution_outdated. Exact replay is idempotent; a different decision or stale goal returns 409. Optional independently edited guidance proposes repository context through the translation PR. The server chooses the context path. The last resolution after runner release queues one continuation; resumed_session_id identifies it."
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
            "The actor's private histories plus shared project linguistic-goal conversations. Shared goals additionally require current Toki write policy permission. Source-linked conversations require current translation:read scope and policy permission and a source still in the same project/account; otherwise they are omitted before pagination and counts."
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
              "Ordinary histories remain private, including for administrators; linguistic-goal histories are shared and record the human author. Closed goals reject new messages with 409 goal_closed. " <>
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
              "handle" => string(),
              "fluent_languages" => array(string()) |> Map.put("maxItems", 50)
            }),
          "server_version" => string()
        }),
      "FluentLanguagesRequest" =>
        object(%{"fluent_languages" => array(string()) |> Map.put("maxItems", 50)})
        |> Map.put("additionalProperties", false),
      "PushCapabilities" =>
        object(%{"ios" => %{"type" => "boolean"}, "android" => %{"type" => "boolean"}}),
      "PushRegistration" =>
        object(%{
          "registered" => %{"type" => "boolean", "const" => true},
          "registration_id" => uuid()
        }),
      "PushDeletion" => object(%{"deleted" => %{"type" => "boolean", "const" => true}}),
      "PushDeviceRequest" =>
        object(%{
          "platform" => %{"type" => "string", "enum" => ~w(ios android)},
          "environment" => %{"type" => "string", "enum" => ~w(sandbox production)},
          "token" => %{
            "type" => "string",
            "maxLength" => 4096,
            "description" =>
              "APNs hex token (32–512 even-length characters), or FCM printable non-space ASCII token (16–4096 characters). Android environment must be production."
          }
        })
        |> Map.put("additionalProperties", false),
      "LinguisticReviews" =>
        object(%{"reviews" => array(ref("LinguisticReview")) |> Map.put("maxItems", 500)}),
      "LinguisticReviewAnswer" => object(%{"review" => ref("LinguisticReview")}),
      "LinguisticReview" =>
        object(%{
          "id" => uuid(),
          "translation_session_id" => uuid(),
          "status" => %{"type" => "string", "enum" => ~w(open answered stale)},
          "source_path" => string(),
          "output_path" => string(),
          "locale" => string(),
          "question" => string(),
          "source_excerpt" => string(),
          "translation_excerpt" => string(),
          "answer" => nullable_string(),
          "guidance" => nullable_string(),
          "context_path" => nullable_string(),
          "resumed_session_id" => nullable_uuid(),
          "resolution_message_id" => nullable_uuid(),
          "conversation_id" => nullable_uuid(),
          "participants" => array(object(%{"id" => uuid(), "name" => nullable_string()})),
          "inserted_at" => timestamp()
        }),
      "LinguisticReviewRequest" =>
        object(%{
          "resolution_message_id" => uuid(),
          "answer" => %{
            "type" => "string",
            "minLength" => 1,
            "maxLength" => 8000,
            "description" => "Non-blank, at most 32,000 UTF-8 bytes."
          },
          "guidance" => %{
            "type" => ["string", "null"],
            "maxLength" => 8000,
            "description" =>
              "Optional reusable instructions explicitly edited by a human; at most 32,000 UTF-8 bytes."
          },
          "context_scope" => %{
            "type" => "string",
            "enum" => ~w(locale project),
            "default" => "locale"
          }
        })
        |> Map.put("required", ["answer", "resolution_message_id"]),
      "MobileTranslations" =>
        object(%{
          "sessions" => array(object(session_properties())),
          "meta" => ref("PaginationMeta")
        }),
      "MobileTranslation" =>
        object(%{
          "session" => object(Map.put(session_properties(), "commit_sha", nullable_string())),
          "progress" => ref("MobileTranslationProgress")
        }),
      "MobileTranslationProgress" =>
        object(%{
          "seq" => %{
            "type" => "integer",
            "minimum" => 0,
            "description" => "Durable progress sequence, not a unique snapshot version"
          },
          "summary" => ref("MobileTranslationProgressSummary"),
          "items" => array(ref("MobileTranslationProgressItem")) |> Map.put("maxItems", 500),
          "omitted_items" => %{
            "type" => "integer",
            "minimum" => 0,
            "description" => "Items omitted by the count or byte budget; summary covers all files"
          }
        }),
      "MobileTranslationProgressSummary" =>
        object(%{
          "total" => integer(),
          "checked" => integer(),
          "needs_translation" => integer(),
          "assessed?" => %{"type" => "boolean"},
          "skipped" => integer(),
          "done" => integer(),
          "failed" => integer(),
          "cancelled" => integer(),
          "awaiting_input" => integer(),
          "running" => integer(),
          "queued" => integer(),
          "glossary" =>
            object(%{
              "applied_ids" => array(string()),
              "shadowed_ids" => array(string()),
              "files_with_applied" => integer(),
              "files_with_shadowed" => integer()
            })
        }),
      "MobileTranslationProgressItem" =>
        object(%{
          "index" => integer(),
          "output_path" => nullable_string(),
          "locale" => nullable_string(),
          "status" => %{
            "type" => "string",
            "enum" => ~w(queued running done failed cancelled awaiting_input)
          },
          "turns" => integer(),
          "file_ref" => nullable_string()
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
          "traffic" =>
            object(%{
              "granularity" => %{"type" => "string", "enum" => ~w(hour day month)},
              "points" =>
                array(
                  object(%{
                    "bucket" =>
                      Map.put(
                        timestamp(),
                        "description",
                        "Start of the UTC bucket, chronological"
                      ),
                    "pageviews" => %{"type" => "integer", "minimum" => 0},
                    "unique_visitors" => %{
                      "type" => "integer",
                      "minimum" => 0,
                      "description" =>
                        "Distinct visitors within this bucket, not additive across buckets"
                    }
                  })
                )
                |> Map.put(
                  "description",
                  "Empty when there are no events; otherwise includes zero-count buckets in the requested window"
                )
            }),
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
          "linguistic_review" => %{
            "anyOf" => [ref("LinguisticReview"), %{"type" => "null"}]
          },
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
                "status" => %{"type" => "string", "enum" => ~w(queued running completed failed)},
                "user_id" => nullable_uuid(),
                "reply_to_id" => nullable_uuid(),
                "author" => string(),
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
      "status" => %{
        "type" => "string",
        "enum" => ~w(pending running completed failed cancelled awaiting_input)
      },
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
