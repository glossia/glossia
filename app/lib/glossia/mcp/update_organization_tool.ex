defmodule Glossia.MCP.UpdateOrganizationTool do
  @moduledoc "Update an organization's name or visibility."

  use Hermes.Server.Component, type: :tool
  use GlossiaWeb, :verified_routes

  alias Glossia.ChangesetErrors
  alias Glossia.Events
  alias Glossia.Organizations
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Organization handle."
    field :name, :string, description: "New display name."
    field :visibility, :string, description: "New visibility (private or public)."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]

    with {:ok, user, account} <- Auth.fetch_organization_context(frame, handle),
         :ok <- Auth.authorize(frame, :organization_write, user, account) do
      org = Organizations.get_organization_for_account(account)
      update_attrs = Map.take(params, ["name", "visibility"])

      case Organizations.update_organization(org, update_attrs) do
        {:ok, org} ->
          Events.emit("organization.updated", org.account, user,
            resource_type: "organization",
            resource_id: to_string(org.id),
            resource_path: ~p"/#{org.account.handle}",
            summary: "Updated organization \"#{org.account.handle}\""
          )

          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                handle: org.account.handle,
                name: org.name,
                type: "organization",
                visibility: org.account.visibility
              })
            )

          {:reply, response, frame}

        {:error, changeset} ->
          errors = ChangesetErrors.to_inline_string(changeset)
          {:error, Hermes.MCP.Error.execution("Update failed: #{errors}"), frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
