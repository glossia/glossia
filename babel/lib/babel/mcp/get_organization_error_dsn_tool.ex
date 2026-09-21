defmodule Babel.MCP.GetOrganizationErrorDsnTool do
  @moduledoc """
  Return the current Sentry-compatible Data Source Name for an organization.

  Lazily provisions one if the organization has none. Babel scopes DSNs to
  organizations (there is no project concept), so callers pass an
  `organization_id` where Sentry docs speak of a "project".
  """

  use Hermes.Server.Component, type: :tool, annotations: %{"readOnlyHint" => true}

  alias Babel.Errors
  alias Babel.MCP.Authorization
  alias BabelWeb.Endpoint
  alias Hermes.MCP.Error
  alias Hermes.Server.Response

  schema do
    field :organization_id, :integer,
      required: true,
      description: "Organization identifier."
  end

  @impl true
  def execute(%{organization_id: org_id}, frame) do
    case Authorization.authorize(frame) do
      :ok ->
        case Errors.primary_key(org_id) do
          nil ->
            {:error, Error.execution("Could not provision DSN for organization"), frame}

          key ->
            response =
              Response.tool()
              |> Response.structured(%{key: Errors.serialize_key(key, Endpoint.url())})

            {:reply, response, frame}
        end

      {:error, error} ->
        {:error, error, frame}
    end
  end
end
