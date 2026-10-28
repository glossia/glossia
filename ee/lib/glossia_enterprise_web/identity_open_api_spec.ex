defmodule GlossiaEnterpriseWeb.IdentityOpenApiSpec do
  @moduledoc false

  def paths do
    %{
      "/api/organizations/{handle}/authentication" => %{
        "get" =>
          operation(
            "getOrganizationAuthentication",
            "Read SSO configuration (client secret is never returned)"
          ),
        "patch" =>
          Map.put(
            operation(
              "updateOrganizationAuthentication",
              "Configure SSO or disable enforcement; enable enforcement only after a tested browser login in Authentication settings"
            ),
            "requestBody",
            %{
              "required" => true,
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "type" => "object",
                    "properties" =>
                      Map.merge(string_fields(), %{
                        "auth_client_secret" => %{
                          "type" => "string",
                          "writeOnly" => true,
                          "description" => "Omit or leave blank to keep the saved secret."
                        },
                        "sso_enforced" => %{
                          "type" => "boolean",
                          "description" =>
                            "Can disable enforcement; enabling requires a tested browser SSO session."
                        }
                      })
                  }
                }
              }
            }
          )
      },
      "/api/organizations/{handle}/authentication/verify" => %{
        "post" =>
          operation(
            "verifyOrganizationAuthentication",
            "Verify SSO domain ownership using the configured DNS TXT record"
          )
      }
    }
  end

  defp string_fields do
    Map.new(
      ~w(auth_provider auth_domain auth_issuer auth_client_id auth_authorize_url auth_token_url auth_userinfo_url),
      &{&1, %{"type" => ["string", "null"]}}
    )
    |> Map.put("auth_provider", %{
      "type" => ["string", "null"],
      "enum" => ["google", "okta", "oauth2", "", nil]
    })
  end

  defp operation(id, summary) do
    %{
      "operationId" => id,
      "summary" => summary,
      "tags" => ["Organizations"],
      "security" => [%{"oauth2" => ["organization:admin"]}],
      "parameters" => [
        %{
          "name" => "handle",
          "in" => "path",
          "required" => true,
          "schema" => %{"type" => "string"}
        }
      ],
      "responses" => %{
        "200" => %{
          "description" => "SSO configuration",
          "content" => %{
            "application/json" => %{
              "schema" => %{
                "type" => "object",
                "properties" =>
                  Map.merge(string_fields(), %{
                    "auth_client_secret_configured" => %{"type" => "boolean"},
                    "sso_enforced" => %{"type" => "boolean"},
                    "domain_verified" => %{"type" => "boolean"},
                    "callback_url" => %{"type" => "string"},
                    "verification_record" => %{
                      "type" => ["object", "null"],
                      "properties" => %{
                        "name" => %{"type" => "string"},
                        "value" => %{"type" => "string"}
                      }
                    }
                  })
              }
            }
          }
        },
        "401" => %{"description" => "Authentication required"},
        "403" => %{
          "description" => "Requires organization administrator and organization:admin scope"
        },
        "404" => %{"description" => "Organization not found"},
        "422" => %{
          "description" =>
            "Invalid configuration, DNS verification failed, enforcement_enabled, or sso_required"
        },
        "429" => %{"description" => "Rate limit exceeded"}
      }
    }
  end
end
