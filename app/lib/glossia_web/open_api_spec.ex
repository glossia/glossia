defmodule GlossiaWeb.OpenApiSpec do
  @moduledoc false

  def spec do
    issuer = Boruta.Config.issuer()
    scopes = build_scopes()

    %{
      "openapi" => "3.1.0",
      "info" => %{
        "title" => "Glossia API",
        "description" =>
          "OAuth 2.1 API for Glossia. Supports dynamic client registration, " <>
            "authorization code flow with PKCE, device authorization flow, " <>
            "token introspection, and revocation.",
        "version" => "1.0.0"
      },
      "servers" => [%{"url" => issuer, "description" => "Glossia server"}],
      "paths" => paths(issuer),
      "components" => %{
        "securitySchemes" => %{
          "oauth2" => %{
            "type" => "oauth2",
            "flows" => %{
              "authorizationCode" => %{
                "authorizationUrl" => "#{issuer}/oauth/authorize",
                "tokenUrl" => "#{issuer}/oauth/token",
                "scopes" => scopes
              }
            }
          },
          "bearerAuth" => %{
            "type" => "http",
            "scheme" => "bearer"
          }
        },
        "schemas" => schemas()
      }
    }
  end

  defp build_scopes do
    Glossia.Authz.available_scopes()
    |> Enum.map(&{&1, ""})
    |> Map.new()
  end

  defp oauth_security(required_scopes) when is_list(required_scopes) do
    [%{"oauth2" => required_scopes}]
  end

  defp organization_roles do
    Glossia.Extensions.organization_roles().valid_roles()
  end

  defp default_organization_role do
    Glossia.Extensions.organization_roles().default_role()
  end

  defp paths(issuer) do
    %{
      "/oauth/register" => %{
        "post" => %{
          "summary" => "Dynamic client registration",
          "description" =>
            "Register a new OAuth client. Rate limited to 5 requests per minute per IP.",
          "operationId" => "registerClient",
          "tags" => ["OAuth"],
          "requestBody" => %{
            "required" => true,
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/ClientRegistrationRequest"}
              }
            }
          },
          "responses" => %{
            "201" => %{
              "description" => "Client registered successfully",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/ClientRegistrationResponse"}
                }
              }
            },
            "400" => %{
              "description" => "Invalid client metadata",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/RegistrationError"}
                }
              }
            },
            "429" => %{"description" => "Rate limit exceeded"}
          }
        }
      },
      "/oauth/device_authorization" => %{
        "post" => %{
          "summary" => "Device authorization",
          "description" =>
            "Start the OAuth 2.0 device flow and return a device_code/user_code pair. " <>
              "Rate limited to 20 requests per minute per IP.",
          "operationId" => "deviceAuthorization",
          "tags" => ["OAuth"],
          "requestBody" => %{
            "required" => true,
            "content" => %{
              "application/x-www-form-urlencoded" => %{
                "schema" => %{"$ref" => "#/components/schemas/DeviceAuthorizationRequest"}
              }
            }
          },
          "responses" => %{
            "200" => %{
              "description" => "Device code issued successfully",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/DeviceAuthorizationResponse"}
                }
              }
            },
            "400" => %{
              "description" => "Invalid request",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/OAuthError"}
                }
              }
            },
            "401" => %{
              "description" => "Invalid client",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/OAuthError"}
                }
              }
            },
            "429" => %{"description" => "Rate limit exceeded"}
          }
        }
      },
      "/oauth/token" => %{
        "post" => %{
          "summary" => "Token exchange",
          "description" =>
            "Exchange an authorization code, refresh token, or device code for an access token. " <>
              "Rate limited to 30 requests per minute per IP.",
          "operationId" => "token",
          "tags" => ["OAuth"],
          "requestBody" => %{
            "required" => true,
            "content" => %{
              "application/x-www-form-urlencoded" => %{
                "schema" => %{"$ref" => "#/components/schemas/TokenRequest"}
              }
            }
          },
          "responses" => %{
            "200" => %{
              "description" => "Token issued successfully",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/TokenResponse"}
                }
              }
            },
            "400" => %{
              "description" => "Invalid request",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/OAuthError"}
                }
              }
            },
            "429" => %{"description" => "Rate limit exceeded"}
          }
        }
      },
      "/oauth/revoke" => %{
        "post" => %{
          "summary" => "Token revocation",
          "description" =>
            "Revoke an access token or refresh token. " <>
              "Rate limited to 30 requests per minute per IP.",
          "operationId" => "revokeToken",
          "tags" => ["OAuth"],
          "requestBody" => %{
            "required" => true,
            "content" => %{
              "application/x-www-form-urlencoded" => %{
                "schema" => %{
                  "type" => "object",
                  "required" => ["token"],
                  "properties" => %{
                    "token" => %{
                      "type" => "string",
                      "description" => "The token to revoke"
                    },
                    "token_type_hint" => %{
                      "type" => "string",
                      "enum" => ["access_token", "refresh_token"],
                      "description" => "Hint about the type of token being revoked"
                    }
                  }
                }
              }
            }
          },
          "responses" => %{
            "200" => %{"description" => "Token revoked successfully"},
            "400" => %{
              "description" => "Invalid request",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/OAuthError"}
                }
              }
            },
            "429" => %{"description" => "Rate limit exceeded"}
          }
        }
      },
      "/oauth/introspect" => %{
        "post" => %{
          "summary" => "Token introspection",
          "description" =>
            "Check the validity and metadata of an access token. " <>
              "Rate limited to 30 requests per minute per IP.",
          "operationId" => "introspectToken",
          "tags" => ["OAuth"],
          "requestBody" => %{
            "required" => true,
            "content" => %{
              "application/x-www-form-urlencoded" => %{
                "schema" => %{
                  "type" => "object",
                  "required" => ["token"],
                  "properties" => %{
                    "token" => %{
                      "type" => "string",
                      "description" => "The token to introspect"
                    }
                  }
                }
              }
            }
          },
          "responses" => %{
            "200" => %{
              "description" => "Token introspection result",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/IntrospectionResponse"}
                }
              }
            },
            "400" => %{
              "description" => "Invalid request",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/OAuthError"}
                }
              }
            },
            "429" => %{"description" => "Rate limit exceeded"}
          }
        }
      },
      "/oauth/authorize" => %{
        "get" => %{
          "summary" => "Authorization",
          "description" =>
            "Initiate the OAuth 2.1 authorization code flow. " <>
              "This is a browser-based endpoint that shows a consent screen.",
          "operationId" => "authorize",
          "tags" => ["OAuth"],
          "parameters" => [
            %{
              "name" => "response_type",
              "in" => "query",
              "required" => true,
              "schema" => %{"type" => "string", "enum" => ["code"]}
            },
            %{
              "name" => "client_id",
              "in" => "query",
              "required" => true,
              "schema" => %{"type" => "string"}
            },
            %{
              "name" => "redirect_uri",
              "in" => "query",
              "required" => true,
              "schema" => %{"type" => "string", "format" => "uri"}
            },
            %{
              "name" => "scope",
              "in" => "query",
              "schema" => %{"type" => "string"},
              "description" => "Space-separated list of scopes"
            },
            %{
              "name" => "state",
              "in" => "query",
              "schema" => %{"type" => "string"},
              "description" => "Opaque value for CSRF protection"
            },
            %{
              "name" => "code_challenge",
              "in" => "query",
              "required" => true,
              "schema" => %{"type" => "string"},
              "description" => "PKCE code challenge (S256)"
            },
            %{
              "name" => "code_challenge_method",
              "in" => "query",
              "required" => true,
              "schema" => %{"type" => "string", "enum" => ["S256"]}
            }
          ],
          "responses" => %{
            "200" => %{"description" => "Consent screen rendered (HTML)"},
            "302" => %{
              "description" => "Redirect to client with authorization code"
            },
            "400" => %{
              "description" => "Invalid authorization request",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/OAuthError"}
                }
              }
            }
          }
        }
      },
      "/.well-known/oauth-authorization-server" => %{
        "get" => %{
          "summary" => "OAuth server metadata",
          "description" => "Returns OAuth 2.0 Authorization Server Metadata per RFC 8414.",
          "operationId" => "oauthServerMetadata",
          "tags" => ["Discovery"],
          "responses" => %{
            "200" => %{
              "description" => "Server metadata",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" => %{
                      "issuer" => %{"type" => "string"},
                      "authorization_endpoint" => %{"type" => "string", "format" => "uri"},
                      "device_authorization_endpoint" => %{
                        "type" => "string",
                        "format" => "uri"
                      },
                      "token_endpoint" => %{"type" => "string", "format" => "uri"},
                      "revocation_endpoint" => %{"type" => "string", "format" => "uri"},
                      "introspection_endpoint" => %{"type" => "string", "format" => "uri"},
                      "registration_endpoint" => %{"type" => "string", "format" => "uri"},
                      "scopes_supported" => %{
                        "type" => "array",
                        "items" => %{"type" => "string"}
                      },
                      "response_types_supported" => %{
                        "type" => "array",
                        "items" => %{"type" => "string"}
                      },
                      "grant_types_supported" => %{
                        "type" => "array",
                        "items" => %{"type" => "string"}
                      },
                      "code_challenge_methods_supported" => %{
                        "type" => "array",
                        "items" => %{"type" => "string"}
                      }
                    }
                  },
                  "example" => %{
                    "issuer" => issuer,
                    "authorization_endpoint" => "#{issuer}/oauth/authorize",
                    "device_authorization_endpoint" => "#{issuer}/oauth/device_authorization",
                    "token_endpoint" => "#{issuer}/oauth/token",
                    "revocation_endpoint" => "#{issuer}/oauth/revoke",
                    "introspection_endpoint" => "#{issuer}/oauth/introspect",
                    "registration_endpoint" => "#{issuer}/oauth/register",
                    "scopes_supported" => Map.keys(build_scopes()),
                    "response_types_supported" => ["code"],
                    "grant_types_supported" => [
                      "authorization_code",
                      "refresh_token",
                      "urn:ietf:params:oauth:grant-type:device_code"
                    ],
                    "code_challenge_methods_supported" => ["S256"]
                  }
                }
              }
            }
          }
        }
      },
      "/.well-known/oauth-protected-resource" => %{
        "get" => %{
          "summary" => "Protected resource metadata",
          "description" => "Returns OAuth 2.0 Protected Resource Metadata per RFC 9728.",
          "operationId" => "protectedResourceMetadata",
          "tags" => ["Discovery"],
          "responses" => %{
            "200" => %{
              "description" => "Resource metadata",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" => %{
                      "resource" => %{"type" => "string"},
                      "authorization_servers" => %{
                        "type" => "array",
                        "items" => %{"type" => "string"}
                      },
                      "scopes_supported" => %{
                        "type" => "array",
                        "items" => %{"type" => "string"}
                      },
                      "bearer_methods_supported" => %{
                        "type" => "array",
                        "items" => %{"type" => "string"}
                      }
                    }
                  }
                }
              }
            }
          }
        }
      },
      "/api/accounts" => %{
        "get" => %{
          "summary" => "List accounts",
          "description" =>
            "Returns all accounts accessible by the current user (personal and organization accounts). " <>
              "Supports pagination, filtering, and sorting via query parameters.",
          "operationId" => "listAccounts",
          "tags" => ["Accounts"],
          "security" => oauth_security(["account:read"]),
          "parameters" =>
            pagination_parameters() ++
              [
                filter_parameter("handle", "string", "Filter by handle"),
                filter_parameter("type", "string", "Filter by type (user or organization)"),
                filter_parameter(
                  "visibility",
                  "string",
                  "Filter by visibility (private or public)"
                ),
                sort_parameter("handle, type, visibility, inserted_at")
              ],
          "responses" => %{
            "200" => %{
              "description" => "Paginated list of accounts",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" => %{
                      "accounts" => %{
                        "type" => "array",
                        "items" => %{
                          "type" => "object",
                          "properties" => %{
                            "handle" => %{"type" => "string"},
                            "type" => %{"type" => "string"},
                            "visibility" => %{"type" => "string"}
                          }
                        }
                      },
                      "meta" => %{"$ref" => "#/components/schemas/PaginationMeta"}
                    }
                  }
                }
              }
            },
            "400" => %{"description" => "Invalid pagination or filter parameters"},
            "401" => %{"description" => "Unauthorized"}
          }
        }
      },
      "/api/{handle}/projects" => %{
        "get" => %{
          "summary" => "List projects",
          "description" =>
            "Returns all projects for a given account. " <>
              "Supports pagination, filtering, and sorting via query parameters.",
          "operationId" => "listProjects",
          "tags" => ["Projects"],
          "security" => oauth_security(["project:read"]),
          "parameters" =>
            [
              %{
                "name" => "handle",
                "in" => "path",
                "required" => true,
                "schema" => %{"type" => "string"},
                "description" => "Account handle"
              }
            ] ++
              pagination_parameters() ++
              [
                filter_parameter("handle", "string", "Filter by project handle"),
                filter_parameter("name", "string", "Filter by project name"),
                sort_parameter("handle, name, inserted_at")
              ],
          "responses" => %{
            "200" => %{
              "description" => "Paginated list of projects",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" => %{
                      "projects" => %{
                        "type" => "array",
                        "items" => %{
                          "type" => "object",
                          "properties" => %{
                            "handle" => %{"type" => "string"},
                            "name" => %{"type" => "string"}
                          }
                        }
                      },
                      "meta" => %{"$ref" => "#/components/schemas/PaginationMeta"}
                    }
                  }
                }
              }
            },
            "400" => %{"description" => "Invalid pagination or filter parameters"},
            "401" => %{"description" => "Unauthorized"},
            "403" => %{"description" => "Not authorized"},
            "404" => %{"description" => "Account not found"}
          }
        }
      },
      "/api/organizations" => %{
        "get" => %{
          "summary" => "List organizations",
          "description" => "Returns all organizations the authenticated user belongs to.",
          "operationId" => "listOrganizations",
          "tags" => ["Organizations"],
          "security" => oauth_security(["organization:read"]),
          "responses" => %{
            "200" => %{
              "description" => "List of organizations",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" => %{
                      "organizations" => %{
                        "type" => "array",
                        "items" => %{"$ref" => "#/components/schemas/OrganizationResponse"}
                      }
                    }
                  }
                }
              }
            },
            "401" => %{"description" => "Unauthorized"}
          }
        },
        "post" => %{
          "summary" => "Create organization",
          "description" => "Create a new organization. The authenticated user becomes the admin.",
          "operationId" => "createOrganization",
          "tags" => ["Organizations"],
          "security" => oauth_security(["organization:write"]),
          "requestBody" => %{
            "required" => true,
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/CreateOrganizationRequest"}
              }
            }
          },
          "responses" => %{
            "201" => %{
              "description" => "Organization created",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/OrganizationResponse"}
                }
              }
            },
            "401" => %{"description" => "Unauthorized"},
            "422" => %{
              "description" => "Validation errors",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" => %{
                      "errors" => %{"type" => "object"}
                    }
                  }
                }
              }
            }
          }
        }
      },
      "/api/organizations/{handle}" => %{
        "get" => %{
          "summary" => "Get organization",
          "description" => "Get details of an organization by handle.",
          "operationId" => "getOrganization",
          "tags" => ["Organizations"],
          "security" => oauth_security(["organization:read"]),
          "parameters" => [handle_parameter()],
          "responses" => %{
            "200" => %{
              "description" => "Organization details",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/OrganizationResponse"}
                }
              }
            },
            "401" => %{"description" => "Unauthorized"},
            "403" => %{"description" => "Not authorized"},
            "404" => %{"description" => "Organization not found"}
          }
        },
        "patch" => %{
          "summary" => "Update organization",
          "description" => "Update an organization's name or visibility.",
          "operationId" => "updateOrganization",
          "tags" => ["Organizations"],
          "security" => oauth_security(["organization:write"]),
          "parameters" => [handle_parameter()],
          "requestBody" => %{
            "required" => true,
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/UpdateOrganizationRequest"}
              }
            }
          },
          "responses" => %{
            "200" => %{
              "description" => "Organization updated",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/OrganizationResponse"}
                }
              }
            },
            "401" => %{"description" => "Unauthorized"},
            "403" => %{"description" => "Not authorized"},
            "404" => %{"description" => "Organization not found"},
            "422" => %{
              "description" => "Validation errors",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" => %{"errors" => %{"type" => "object"}}
                  }
                }
              }
            }
          }
        },
        "delete" => %{
          "summary" => "Delete organization",
          "description" => "Delete an organization and all associated data.",
          "operationId" => "deleteOrganization",
          "tags" => ["Organizations"],
          "security" => oauth_security(["organization:delete"]),
          "parameters" => [handle_parameter()],
          "responses" => %{
            "204" => %{"description" => "Organization deleted"},
            "401" => %{"description" => "Unauthorized"},
            "403" => %{"description" => "Not authorized"},
            "404" => %{"description" => "Organization not found"}
          }
        }
      },
      "/api/organizations/{handle}/members" => %{
        "get" => %{
          "summary" => "List organization members",
          "description" => "Returns all members of an organization.",
          "operationId" => "listOrganizationMembers",
          "tags" => ["Organizations"],
          "security" => oauth_security(["members:read"]),
          "parameters" => [handle_parameter()],
          "responses" => %{
            "200" => %{
              "description" => "List of members",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" => %{
                      "members" => %{
                        "type" => "array",
                        "items" => %{"$ref" => "#/components/schemas/MemberResponse"}
                      }
                    }
                  }
                }
              }
            },
            "401" => %{"description" => "Unauthorized"},
            "403" => %{"description" => "Not authorized"},
            "404" => %{"description" => "Organization not found"}
          }
        }
      },
      "/api/organizations/{handle}/members/{user_handle}" => %{
        "delete" => %{
          "summary" => "Remove organization member",
          "description" => "Remove a member from an organization. Cannot remove the last admin.",
          "operationId" => "removeOrganizationMember",
          "tags" => ["Organizations"],
          "security" => oauth_security(["members:write"]),
          "parameters" => [
            handle_parameter(),
            %{
              "name" => "user_handle",
              "in" => "path",
              "required" => true,
              "schema" => %{"type" => "string"},
              "description" => "Handle of the user to remove"
            }
          ],
          "responses" => %{
            "204" => %{"description" => "Member removed"},
            "401" => %{"description" => "Unauthorized"},
            "403" => %{"description" => "Not authorized"},
            "404" => %{"description" => "Organization or user not found"},
            "409" => %{"description" => "Cannot remove the only admin"}
          }
        }
      },
      "/api/organizations/{handle}/invitations" => %{
        "get" => %{
          "summary" => "List organization invitations",
          "description" => "Returns all pending invitations for an organization.",
          "operationId" => "listOrganizationInvitations",
          "tags" => ["Organizations"],
          "security" => oauth_security(["members:read"]),
          "parameters" => [handle_parameter()],
          "responses" => %{
            "200" => %{
              "description" => "List of pending invitations",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" => %{
                      "invitations" => %{
                        "type" => "array",
                        "items" => %{"$ref" => "#/components/schemas/InvitationResponse"}
                      }
                    }
                  }
                }
              }
            },
            "401" => %{"description" => "Unauthorized"},
            "403" => %{"description" => "Not authorized"},
            "404" => %{"description" => "Organization not found"}
          }
        },
        "post" => %{
          "summary" => "Create organization invitation",
          "description" => "Invite a user to an organization by email.",
          "operationId" => "createOrganizationInvitation",
          "tags" => ["Organizations"],
          "security" => oauth_security(["members:write"]),
          "parameters" => [handle_parameter()],
          "requestBody" => %{
            "required" => true,
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/CreateInvitationRequest"}
              }
            }
          },
          "responses" => %{
            "201" => %{
              "description" => "Invitation created",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/InvitationResponse"}
                }
              }
            },
            "401" => %{"description" => "Unauthorized"},
            "403" => %{"description" => "Not authorized"},
            "404" => %{"description" => "Organization not found"},
            "409" => %{"description" => "User already a member or already invited"},
            "422" => %{
              "description" => "Validation errors",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" => %{"errors" => %{"type" => "object"}}
                  }
                }
              }
            }
          }
        }
      },
      "/api/organizations/{handle}/invitations/{invitation_id}" => %{
        "delete" => %{
          "summary" => "Revoke organization invitation",
          "description" => "Revoke a pending invitation.",
          "operationId" => "revokeOrganizationInvitation",
          "tags" => ["Organizations"],
          "security" => oauth_security(["members:write"]),
          "parameters" => [
            handle_parameter(),
            %{
              "name" => "invitation_id",
              "in" => "path",
              "required" => true,
              "schema" => %{"type" => "string"},
              "description" => "Invitation ID"
            }
          ],
          "responses" => %{
            "204" => %{"description" => "Invitation revoked"},
            "401" => %{"description" => "Unauthorized"},
            "403" => %{"description" => "Not authorized"},
            "404" => %{"description" => "Organization or invitation not found"}
          }
        }
      },
      "/api/{handle}/voice" => %{
        "get" => %{
          "summary" => "Get voice configuration",
          "description" =>
            "Get the latest voice configuration for an account. " <>
              "Optionally specify a locale to get a merged/resolved voice, or a version number.",
          "operationId" => "getVoice",
          "tags" => ["Voice"],
          "security" => oauth_security(["voice:read"]),
          "parameters" => [
            %{
              "name" => "handle",
              "in" => "path",
              "required" => true,
              "schema" => %{"type" => "string"}
            },
            %{
              "name" => "locale",
              "in" => "query",
              "schema" => %{"type" => "string"},
              "description" => "Locale to resolve overrides for (e.g. 'ja', 'de')"
            },
            %{
              "name" => "version",
              "in" => "query",
              "schema" => %{"type" => "integer"},
              "description" => "Specific version number to retrieve"
            }
          ],
          "responses" => %{
            "200" => %{
              "description" => "Voice configuration",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/VoiceResponse"}
                }
              }
            },
            "404" => %{"description" => "Account or voice not found"}
          }
        },
        "post" => %{
          "summary" => "Create new voice version",
          "description" => "Create a new voice configuration version for an account.",
          "operationId" => "createVoice",
          "tags" => ["Voice"],
          "security" => oauth_security(["voice:write"]),
          "parameters" => [
            %{
              "name" => "handle",
              "in" => "path",
              "required" => true,
              "schema" => %{"type" => "string"}
            }
          ],
          "requestBody" => %{
            "required" => true,
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/CreateVoiceRequest"}
              }
            }
          },
          "responses" => %{
            "201" => %{
              "description" => "Voice version created",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/VoiceResponse"}
                }
              }
            },
            "422" => %{
              "description" => "Validation errors",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" => %{"errors" => %{"type" => "object"}}
                  }
                }
              }
            }
          }
        }
      },
      "/api/{handle}/voice/history" => %{
        "get" => %{
          "summary" => "List voice version history",
          "description" =>
            "Returns a paginated list of all voice versions for an account. " <>
              "Supports pagination, filtering, and sorting via query parameters.",
          "operationId" => "getVoiceHistory",
          "tags" => ["Voice"],
          "security" => oauth_security(["voice:read"]),
          "parameters" =>
            [
              %{
                "name" => "handle",
                "in" => "path",
                "required" => true,
                "schema" => %{"type" => "string"}
              }
            ] ++
              pagination_parameters() ++
              [
                filter_parameter("version", "integer", "Filter by version number"),
                filter_parameter("tone", "string", "Filter by tone"),
                filter_parameter("formality", "string", "Filter by formality"),
                sort_parameter("version, inserted_at")
              ],
          "responses" => %{
            "200" => %{
              "description" => "Paginated voice version history",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" => %{
                      "versions" => %{
                        "type" => "array",
                        "items" => %{
                          "type" => "object",
                          "properties" => %{
                            "version" => %{"type" => "integer"},
                            "inserted_at" => %{"type" => "string", "format" => "date-time"}
                          }
                        }
                      },
                      "meta" => %{"$ref" => "#/components/schemas/PaginationMeta"}
                    }
                  }
                }
              }
            },
            "400" => %{"description" => "Invalid pagination or filter parameters"},
            "404" => %{"description" => "Account not found"}
          }
        }
      },
      "/api/{handle}/glossary" => %{
        "get" => %{
          "summary" => "Get glossary",
          "description" =>
            "Get the latest glossary for an account. " <>
              "Optionally specify a locale to get entries with translations for that locale, or a version number.",
          "operationId" => "getGlossary",
          "tags" => ["Glossary"],
          "security" => oauth_security(["glossary:read"]),
          "parameters" => [
            %{
              "name" => "handle",
              "in" => "path",
              "required" => true,
              "schema" => %{"type" => "string"}
            },
            %{
              "name" => "locale",
              "in" => "query",
              "schema" => %{"type" => "string"},
              "description" => "Locale to filter translations for (e.g. 'ja', 'de')"
            },
            %{
              "name" => "version",
              "in" => "query",
              "schema" => %{"type" => "integer"},
              "description" => "Specific version number to retrieve"
            }
          ],
          "responses" => %{
            "200" => %{
              "description" => "Glossary with entries and translations",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/GlossaryResponse"}
                }
              }
            },
            "404" => %{"description" => "Account or glossary not found"}
          }
        },
        "post" => %{
          "summary" => "Create new glossary version",
          "description" => "Create a new glossary version for an account.",
          "operationId" => "createGlossary",
          "tags" => ["Glossary"],
          "security" => oauth_security(["glossary:write"]),
          "parameters" => [
            %{
              "name" => "handle",
              "in" => "path",
              "required" => true,
              "schema" => %{"type" => "string"}
            }
          ],
          "requestBody" => %{
            "required" => true,
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/CreateGlossaryRequest"}
              }
            }
          },
          "responses" => %{
            "201" => %{
              "description" => "Glossary version created",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"$ref" => "#/components/schemas/GlossaryResponse"}
                }
              }
            },
            "422" => %{
              "description" => "Validation errors",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" => %{"errors" => %{"type" => "object"}}
                  }
                }
              }
            }
          }
        }
      },
      "/api/{handle}/glossary/history" => %{
        "get" => %{
          "summary" => "List glossary version history",
          "description" =>
            "Returns a paginated list of all glossary versions for an account. " <>
              "Supports pagination, filtering, and sorting via query parameters.",
          "operationId" => "getGlossaryHistory",
          "tags" => ["Glossary"],
          "security" => oauth_security(["glossary:read"]),
          "parameters" =>
            [
              %{
                "name" => "handle",
                "in" => "path",
                "required" => true,
                "schema" => %{"type" => "string"}
              }
            ] ++
              pagination_parameters() ++
              [
                filter_parameter("version", "integer", "Filter by version number"),
                filter_parameter("change_note", "string", "Filter by change note"),
                sort_parameter("version, inserted_at")
              ],
          "responses" => %{
            "200" => %{
              "description" => "Paginated glossary version history",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" => %{
                      "versions" => %{
                        "type" => "array",
                        "items" => %{
                          "type" => "object",
                          "properties" => %{
                            "version" => %{"type" => "integer"},
                            "change_note" => %{"type" => "string"},
                            "inserted_at" => %{"type" => "string", "format" => "date-time"}
                          }
                        }
                      },
                      "meta" => %{"$ref" => "#/components/schemas/PaginationMeta"}
                    }
                  }
                }
              }
            },
            "400" => %{"description" => "Invalid pagination or filter parameters"},
            "404" => %{"description" => "Account not found"}
          }
        }
      },
      "/up" => %{
        "get" => %{
          "summary" => "Health check",
          "description" => "Returns 200 if the server is running.",
          "operationId" => "healthCheck",
          "tags" => ["System"],
          "responses" => %{
            "200" => %{
              "description" => "Server is healthy",
              "content" => %{
                "text/plain" => %{
                  "schema" => %{"type" => "string", "example" => "ok"}
                }
              }
            }
          }
        }
      }
    }
  end

  defp schemas do
    %{
      "ClientRegistrationRequest" => %{
        "type" => "object",
        "required" => ["client_name", "redirect_uris"],
        "properties" => %{
          "client_name" => %{
            "type" => "string",
            "description" => "Human-readable name for the client"
          },
          "redirect_uris" => %{
            "type" => "array",
            "items" => %{"type" => "string", "format" => "uri"},
            "description" => "List of allowed redirect URIs"
          },
          "grant_types" => %{
            "type" => "array",
            "items" => %{"type" => "string"},
            "description" => "Requested grant types",
            "default" => ["authorization_code"]
          },
          "token_endpoint_auth_method" => %{
            "type" => "string",
            "description" =>
              "Authentication method for the token endpoint. " <>
                "\"none\" is accepted but treated as default (PKCE enforces proof).",
            "default" => "client_secret_basic"
          },
          "jwks" => %{
            "type" => "object",
            "description" => "JSON Web Key Set for the client"
          },
          "jwks_uri" => %{
            "type" => "string",
            "format" => "uri",
            "description" => "URL for the client's JSON Web Key Set"
          },
          "logo_uri" => %{
            "type" => "string",
            "format" => "uri",
            "description" => "URL for the client's logo"
          }
        }
      },
      "ClientRegistrationResponse" => %{
        "type" => "object",
        "properties" => %{
          "client_id" => %{"type" => "string"},
          "client_secret" => %{"type" => "string"},
          "redirect_uris" => %{
            "type" => "array",
            "items" => %{"type" => "string", "format" => "uri"}
          },
          "grant_types" => %{
            "type" => "array",
            "items" => %{"type" => "string"}
          },
          "token_endpoint_auth_method" => %{"type" => "string"}
        }
      },
      "RegistrationError" => %{
        "type" => "object",
        "properties" => %{
          "error" => %{"type" => "string", "example" => "invalid_client_metadata"},
          "error_description" => %{"type" => "object"}
        }
      },
      "DeviceAuthorizationRequest" => %{
        "type" => "object",
        "required" => ["client_id"],
        "properties" => %{
          "client_id" => %{"type" => "string"},
          "client_secret" => %{"type" => "string"},
          "scope" => %{
            "type" => "string",
            "description" => "Space-separated list of requested scopes"
          }
        }
      },
      "DeviceAuthorizationResponse" => %{
        "type" => "object",
        "required" => [
          "device_code",
          "user_code",
          "verification_uri",
          "verification_uri_complete",
          "expires_in",
          "interval"
        ],
        "properties" => %{
          "device_code" => %{"type" => "string"},
          "user_code" => %{"type" => "string"},
          "verification_uri" => %{"type" => "string", "format" => "uri"},
          "verification_uri_complete" => %{"type" => "string", "format" => "uri"},
          "expires_in" => %{"type" => "integer"},
          "interval" => %{"type" => "integer"}
        }
      },
      "TokenRequest" => %{
        "type" => "object",
        "required" => ["grant_type"],
        "properties" => %{
          "grant_type" => %{
            "type" => "string",
            "enum" => [
              "authorization_code",
              "refresh_token",
              "urn:ietf:params:oauth:grant-type:device_code"
            ]
          },
          "code" => %{
            "type" => "string",
            "description" => "Authorization code (for authorization_code grant)"
          },
          "redirect_uri" => %{
            "type" => "string",
            "format" => "uri",
            "description" => "Must match the redirect_uri used in the authorization request"
          },
          "client_id" => %{"type" => "string"},
          "client_secret" => %{"type" => "string"},
          "code_verifier" => %{
            "type" => "string",
            "description" => "PKCE code verifier"
          },
          "refresh_token" => %{
            "type" => "string",
            "description" => "Refresh token (for refresh_token grant)"
          },
          "device_code" => %{
            "type" => "string",
            "description" =>
              "Device code returned by /oauth/device_authorization (for device_code grant)"
          }
        }
      },
      "TokenResponse" => %{
        "type" => "object",
        "properties" => %{
          "access_token" => %{"type" => "string"},
          "token_type" => %{"type" => "string", "example" => "Bearer"},
          "expires_in" => %{"type" => "integer", "description" => "Token lifetime in seconds"},
          "refresh_token" => %{"type" => "string"},
          "id_token" => %{"type" => "string"}
        },
        "required" => ["access_token", "token_type", "expires_in"]
      },
      "IntrospectionResponse" => %{
        "type" => "object",
        "properties" => %{
          "active" => %{"type" => "boolean"},
          "client_id" => %{"type" => "string"},
          "username" => %{"type" => "string"},
          "scope" => %{"type" => "string"},
          "sub" => %{"type" => "string"},
          "iss" => %{"type" => "string"},
          "exp" => %{"type" => "integer"},
          "iat" => %{"type" => "integer"}
        }
      },
      "OAuthError" => %{
        "type" => "object",
        "properties" => %{
          "error" => %{"type" => "string"},
          "error_description" => %{"type" => "string"}
        }
      },
      "CreateOrganizationRequest" => %{
        "type" => "object",
        "required" => ["handle"],
        "properties" => %{
          "handle" => %{
            "type" => "string",
            "description" =>
              "Organization handle. Lowercase letters, numbers, and hyphens only. Must start with a letter.",
            "pattern" => "^[a-z][a-z0-9-]*$",
            "minLength" => 2,
            "maxLength" => 39
          },
          "name" => %{
            "type" => "string",
            "description" =>
              "Display name for the organization. Defaults to the handle if omitted."
          }
        }
      },
      "OrganizationResponse" => %{
        "type" => "object",
        "properties" => %{
          "handle" => %{"type" => "string"},
          "name" => %{"type" => "string"},
          "type" => %{"type" => "string", "example" => "organization"},
          "visibility" => %{"type" => "string", "enum" => ["private", "public"]}
        }
      },
      "UpdateOrganizationRequest" => %{
        "type" => "object",
        "properties" => %{
          "name" => %{
            "type" => "string",
            "description" => "New display name for the organization."
          },
          "visibility" => %{
            "type" => "string",
            "enum" => ["private", "public"],
            "description" => "New visibility setting."
          }
        }
      },
      "MemberResponse" => %{
        "type" => "object",
        "properties" => %{
          "handle" => %{"type" => "string"},
          "email" => %{"type" => "string"},
          "role" => %{"type" => "string", "enum" => organization_roles()},
          "joined_at" => %{"type" => "string", "format" => "date-time"}
        }
      },
      "InvitationResponse" => %{
        "type" => "object",
        "properties" => %{
          "id" => %{"type" => "string"},
          "email" => %{"type" => "string"},
          "role" => %{"type" => "string", "enum" => organization_roles()},
          "status" => %{"type" => "string"},
          "expires_at" => %{"type" => "string", "format" => "date-time"}
        }
      },
      "CreateInvitationRequest" => %{
        "type" => "object",
        "required" => ["email"],
        "properties" => %{
          "email" => %{
            "type" => "string",
            "description" => "Email address to invite."
          },
          "role" => %{
            "type" => "string",
            "enum" => organization_roles(),
            "description" => "Role for the invitee. Defaults to #{default_organization_role()}.",
            "default" => default_organization_role()
          }
        }
      },
      "CreateVoiceRequest" => %{
        "type" => "object",
        "properties" => %{
          "tone" => %{
            "type" => "string",
            "enum" => ["casual", "formal", "playful", "authoritative", "neutral"]
          },
          "formality" => %{
            "type" => "string",
            "enum" => ["informal", "neutral", "formal", "very_formal"]
          },
          "target_audience" => %{"type" => "string"},
          "guidelines" => %{"type" => "string", "description" => "Markdown content"},
          "overrides" => %{
            "type" => "array",
            "items" => %{"$ref" => "#/components/schemas/VoiceOverride"}
          }
        }
      },
      "VoiceResponse" => %{
        "type" => "object",
        "properties" => %{
          "version" => %{"type" => "integer"},
          "tone" => %{"type" => "string"},
          "formality" => %{"type" => "string"},
          "target_audience" => %{"type" => "string"},
          "guidelines" => %{"type" => "string"},
          "inserted_at" => %{"type" => "string", "format" => "date-time"},
          "overrides" => %{
            "type" => "array",
            "items" => %{"$ref" => "#/components/schemas/VoiceOverride"}
          }
        }
      },
      "VoiceOverride" => %{
        "type" => "object",
        "required" => ["locale"],
        "properties" => %{
          "locale" => %{"type" => "string", "description" => "e.g. 'ja', 'de', 'es-MX'"},
          "tone" => %{"type" => "string"},
          "formality" => %{"type" => "string"},
          "target_audience" => %{"type" => "string"},
          "guidelines" => %{"type" => "string"}
        }
      },
      "CreateGlossaryRequest" => %{
        "type" => "object",
        "properties" => %{
          "change_note" => %{"type" => "string"},
          "entries" => %{
            "type" => "array",
            "items" => %{"$ref" => "#/components/schemas/GlossaryEntryInput"}
          }
        }
      },
      "GlossaryEntryInput" => %{
        "type" => "object",
        "required" => ["term"],
        "properties" => %{
          "term" => %{"type" => "string", "description" => "The canonical source term"},
          "definition" => %{
            "type" => "string",
            "description" => "Context or description for the term"
          },
          "case_sensitive" => %{
            "type" => "boolean",
            "default" => false,
            "description" => "Whether the term should be matched case-sensitively"
          },
          "translations" => %{
            "type" => "array",
            "items" => %{"$ref" => "#/components/schemas/GlossaryTranslationInput"}
          }
        }
      },
      "GlossaryTranslationInput" => %{
        "type" => "object",
        "required" => ["locale", "translation"],
        "properties" => %{
          "locale" => %{
            "type" => "string",
            "description" => "Locale code (e.g. 'ja', 'de', 'es-MX')"
          },
          "translation" => %{
            "type" => "string",
            "description" => "The approved translation for this locale"
          }
        }
      },
      "GlossaryResponse" => %{
        "type" => "object",
        "properties" => %{
          "version" => %{"type" => "integer"},
          "change_note" => %{"type" => "string"},
          "inserted_at" => %{"type" => "string", "format" => "date-time"},
          "entries" => %{
            "type" => "array",
            "items" => %{
              "type" => "object",
              "properties" => %{
                "term" => %{"type" => "string"},
                "definition" => %{"type" => "string"},
                "case_sensitive" => %{"type" => "boolean"},
                "translations" => %{
                  "type" => "array",
                  "items" => %{
                    "type" => "object",
                    "properties" => %{
                      "locale" => %{"type" => "string"},
                      "translation" => %{"type" => "string"}
                    }
                  }
                }
              }
            }
          }
        }
      },
      "PaginationMeta" => %{
        "type" => "object",
        "description" => "Pagination metadata included in all list responses.",
        "properties" => %{
          "total_count" => %{
            "type" => "integer",
            "description" => "Total number of records matching the query"
          },
          "total_pages" => %{
            "type" => "integer",
            "description" => "Total number of pages"
          },
          "current_page" => %{
            "type" => "integer",
            "description" => "Current page number (1-based)"
          },
          "page_size" => %{
            "type" => "integer",
            "description" => "Number of records per page"
          },
          "has_next_page?" => %{
            "type" => "boolean",
            "description" => "Whether a next page exists"
          },
          "has_previous_page?" => %{
            "type" => "boolean",
            "description" => "Whether a previous page exists"
          }
        }
      }
    }
  end

  defp pagination_parameters do
    [
      %{
        "name" => "page",
        "in" => "query",
        "schema" => %{"type" => "integer", "minimum" => 1, "default" => 1},
        "description" => "Page number (1-based)"
      },
      %{
        "name" => "page_size",
        "in" => "query",
        "schema" => %{"type" => "integer", "minimum" => 1, "maximum" => 100, "default" => 20},
        "description" => "Number of records per page (max 100)"
      }
    ]
  end

  defp filter_parameter(field, type, description) do
    %{
      "name" => "filters[#{field}]",
      "in" => "query",
      "schema" => %{"type" => type},
      "description" => description
    }
  end

  defp sort_parameter(fields) do
    %{
      "name" => "order_by[]",
      "in" => "query",
      "schema" => %{"type" => "string"},
      "description" => "Sort field. Allowed values: #{fields}. Prefix with - for descending."
    }
  end

  defp handle_parameter do
    %{
      "name" => "handle",
      "in" => "path",
      "required" => true,
      "schema" => %{"type" => "string"},
      "description" => "Organization handle"
    }
  end
end
