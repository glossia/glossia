defmodule BabelWeb.MCPAuthorization do
  @moduledoc false

  def protected_resource_metadata_url do
    BabelWeb.Endpoint.url()
    |> URI.merge("/.well-known/oauth-protected-resource/mcp")
    |> URI.to_string()
  end

  def www_authenticate do
    ~s(Bearer resource_metadata="#{protected_resource_metadata_url()}")
  end
end
