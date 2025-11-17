defmodule GlossiaWeb.ApiSpec do
  @moduledoc """
  OpenAPI specification for the Glossia API.
  """

  alias OpenApiSpex.{Info, OpenApi, Paths, Server}
  alias GlossiaWeb.{Endpoint, Router}

  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [
        Server.from_endpoint(Endpoint)
      ],
      info: %Info{
        title: "Glossia API",
        version: "1.0.0",
        description: """
        AI-powered translation API for the Glossia platform.

        This API provides endpoints for translating text between different locales
        using AI models (currently Anthropic Claude).
        """
      },
      paths: Paths.from_router(Router)
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
