defmodule Glossia.MCP.DeleteOrganizationTool do
  @moduledoc "Delete an organization."

  use Hermes.Server.Component, type: :tool
  use GlossiaWeb, :verified_routes

  alias Glossia.Events
  alias Glossia.Organizations
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Organization handle to delete."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]

    with {:ok, user, account} <- Auth.fetch_organization_context(frame, handle),
         :ok <- Auth.authorize(frame, :organization_delete, user, account) do
      org = Organizations.get_organization_for_account(account)

      case Organizations.delete_organization(org) do
        {:ok, _} ->
          Events.emit("organization.deleted", account, user,
            resource_type: "organization",
            resource_id: to_string(org.id),
            resource_path: ~p"/#{account.handle}",
            summary: "Deleted organization \"#{account.handle}\""
          )

          response =
            Response.tool()
            |> Response.text(JSON.encode!(%{deleted: true, handle: handle}))

          {:reply, response, frame}

        {:error, _changeset} ->
          {:error, Hermes.MCP.Error.execution("Failed to delete organization '#{handle}'"), frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
