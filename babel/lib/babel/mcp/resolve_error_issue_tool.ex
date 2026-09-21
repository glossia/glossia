defmodule Babel.MCP.ResolveErrorIssueTool do
  @moduledoc "Mark an error issue as resolved, scoped to an organization."

  use Hermes.Server.Component, type: :tool

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
    with :ok <- Authorization.authorize_write(frame),
         {:ok, issue} <- Errors.get_issue(org_id, issue_id),
         {:ok, resolved} <- Errors.resolve_issue(issue) do
      response =
        Response.tool()
        |> Response.structured(%{issue: Errors.serialize_issue(resolved, Endpoint.url())})

      {:reply, response, frame}
    else
      {:error, %Error{} = err} -> {:error, err, frame}
      {:error, :not_found} -> {:error, Error.execution("Issue not found"), frame}
      {:error, other} -> {:error, Error.execution("Update failed: #{inspect(other)}"), frame}
    end
  end
end
