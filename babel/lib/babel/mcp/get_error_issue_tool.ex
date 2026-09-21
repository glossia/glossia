defmodule Babel.MCP.GetErrorIssueTool do
  @moduledoc "Fetch a single error issue by id, scoped to an organization."

  use Hermes.Server.Component, type: :tool, annotations: %{"readOnlyHint" => true}

  alias Babel.Errors
  alias Babel.MCP.Authorization
  alias BabelWeb.Endpoint
  alias Hermes.MCP.Error
  alias Hermes.Server.Response

  schema do
    field :organization_id, :integer,
      required: true,
      description: "Organization that owns the issue."

    field :issue_id, :string,
      required: true,
      description: "Issue identifier (UUID)."
  end

  @impl true
  def execute(%{organization_id: org_id, issue_id: issue_id}, frame) do
    case Authorization.authorize(frame) do
      :ok ->
        case Errors.get_issue(org_id, issue_id) do
          {:ok, issue} ->
            response =
              Response.tool()
              |> Response.structured(%{issue: Errors.serialize_issue(issue, Endpoint.url())})

            {:reply, response, frame}

          {:error, :not_found} ->
            {:error, Error.execution("Issue not found"), frame}
        end

      {:error, error} ->
        {:error, error, frame}
    end
  end
end
