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
            "authorization code flow with PKCE, token introspection, and revocation.",
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
    Glossia.Policy.list_rules()
    |> Enum.map(fn rule -> {"#{rule.object}:#{rule.action}", ""} end)
    |> Map.new()
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
      "/oauth/token" => %{
        "post" => %{
          "summary" => "Token exchange",
          "description" =>
            "Exchange an authorization code or refresh token for an access token. " <>
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
                    "token_endpoint" => "#{issuer}/oauth/token",
                    "revocation_endpoint" => "#{issuer}/oauth/revoke",
                    "introspection_endpoint" => "#{issuer}/oauth/introspect",
                    "registration_endpoint" => "#{issuer}/oauth/register",
                    "scopes_supported" => Map.keys(build_scopes()),
                    "response_types_supported" => ["code"],
                    "grant_types_supported" => ["authorization_code", "refresh_token"],
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
      "/api/organizations" => %{
        "post" => %{
          "summary" => "Create organization",
          "description" =>
            "Create a new organization. The authenticated user becomes the admin.",
          "operationId" => "createOrganization",
          "tags" => ["Organizations"],
          "security" => [%{"bearerAuth" => []}],
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
      "TokenRequest" => %{
        "type" => "object",
        "required" => ["grant_type"],
        "properties" => %{
          "grant_type" => %{
            "type" => "string",
            "enum" => ["authorization_code", "refresh_token"]
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
            "description" => "Display name for the organization. Defaults to the handle if omitted."
          }
        }
      },
      "OrganizationResponse" => %{
        "type" => "object",
        "properties" => %{
          "handle" => %{"type" => "string"},
          "name" => %{"type" => "string"},
          "type" => %{"type" => "string", "example" => "organization"}
        }
      }
    }
  end
end
