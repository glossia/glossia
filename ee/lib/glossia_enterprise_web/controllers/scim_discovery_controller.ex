# Adapted from Tuist's SCIM discovery, Copyright (c) 2025 Tuist GmbH.
# FCL-1.0-MIT; see ee/licenses/TUIST-FCL-1.0-MIT.md.
defmodule GlossiaEnterpriseWeb.SCIMDiscoveryController do
  use GlossiaWeb, :controller
  alias GlossiaEnterprise.SCIM.Protocol

  def config(conn, _) do
    Protocol.send_json(conn, 200, %{
      schemas: ["urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig"],
      patch: %{supported: true},
      filter: %{supported: true, maxResults: 200},
      bulk: %{supported: false, maxOperations: 0, maxPayloadSize: 0},
      changePassword: %{supported: false},
      sort: %{supported: false},
      etag: %{supported: false},
      authenticationSchemes: [
        %{
          type: "oauthbearertoken",
          name: "SCIM bearer token",
          primary: true,
          description: "Organization token generated in Authentication settings",
          specUri: "https://www.rfc-editor.org/rfc/rfc6750"
        }
      ]
    })
  end

  def resource_types(conn, params), do: discovery(conn, params, resource_types())
  def schemas(conn, params), do: discovery(conn, params, schemas())

  defp discovery(conn, %{"id" => id}, resources) do
    case Enum.find(resources, &(&1.id == id)) do
      nil -> Protocol.error(conn, 404, "Resource not found")
      resource -> Protocol.send_json(conn, 200, resource)
    end
  end

  defp discovery(conn, _, resources),
    do: Protocol.send_json(conn, 200, Protocol.render_list(resources, length(resources), 1))

  defp resource_types do
    for {name, schema, endpoint} <- [
          {"User", Protocol.user_schema(), "/Users"},
          {"Group", Protocol.group_schema(), "/Groups"}
        ] do
      %{
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:ResourceType"],
        id: name,
        name: name,
        endpoint: endpoint,
        schema: schema
      }
    end
  end

  defp schemas do
    [
      %{
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:Schema"],
        id: Protocol.user_schema(),
        name: "User",
        attributes: [
          attribute("userName", "string",
            required: true,
            mutability: "immutable",
            uniqueness: "server"
          ),
          attribute("displayName", "string"),
          attribute("externalId", "string"),
          attribute("active", "boolean"),
          attribute("roles", "complex",
            multiValued: true,
            subAttributes: [attribute("value", "string")]
          ),
          attribute("emails", "complex",
            multiValued: true,
            mutability: "readOnly",
            subAttributes: [
              attribute("value", "string"),
              attribute("primary", "boolean"),
              attribute("type", "string")
            ]
          )
        ]
      },
      %{
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:Schema"],
        id: Protocol.group_schema(),
        name: "Group",
        attributes: [
          attribute("displayName", "string", required: true, mutability: "readOnly"),
          attribute("members", "complex",
            multiValued: true,
            subAttributes: [attribute("value", "string")]
          )
        ]
      }
    ]
  end

  defp attribute(name, type, opts \\ []) do
    Map.merge(
      %{
        name: name,
        type: type,
        multiValued: false,
        required: false,
        mutability: "readWrite",
        returned: "default",
        uniqueness: "none",
        caseExact: false
      },
      Map.new(opts)
    )
  end
end
