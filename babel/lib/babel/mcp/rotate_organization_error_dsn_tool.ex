defmodule Babel.MCP.RotateOrganizationErrorDsnTool do
  @moduledoc """
  Invalidate the current Sentry-compatible DSN for an organization and
  return the freshly minted replacement. Restricted to write scope.
  """

  use Hermes.Server.Component, type: :tool

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
    case Authorization.authorize_write(frame) do
      :ok ->
        case Errors.rotate_key(org_id) do
          {:ok, key} ->
            response =
              Response.tool()
              |> Response.structured(%{key: Errors.serialize_key(key, Endpoint.url())})

            {:reply, response, frame}

          {:error, reason} ->
            {:error, Error.execution("Rotation failed: #{inspect(reason)}"), frame}
        end

      {:error, error} ->
        {:error, error, frame}
    end
  end
end
