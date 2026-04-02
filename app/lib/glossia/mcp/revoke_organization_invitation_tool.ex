defmodule Glossia.MCP.RevokeOrganizationInvitationTool do
  @moduledoc "Revoke a pending invitation for an organization."

  use Hermes.Server.Component, type: :tool
  use GlossiaWeb, :verified_routes

  alias Glossia.Auditing
  alias Glossia.Organizations
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Organization handle."
    field :invitation_id, {:required, :string}, description: "ID of the invitation to revoke."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]
    invitation_id = params["invitation_id"]

    with {:ok, user, account} <- Auth.fetch_organization_context(frame, handle),
         :ok <- Auth.authorize(frame, :members_write, user, account) do
      org = Organizations.get_organization_for_account(account)

      case Organizations.get_invitation(org, invitation_id) do
        nil ->
          {:error, Hermes.MCP.Error.execution("Invitation not found"), frame}

        invitation ->
          case Organizations.revoke_invitation(invitation) do
            {:ok, _} ->
              Auditing.record("member.invitation_revoked", account, user,
                resource_type: "invitation",
                resource_id: to_string(invitation.id),
                resource_path: "/#{account.handle}/-/members",
                summary: "Revoked invitation for #{invitation.email}"
              )

              response =
                Response.tool()
                |> Response.text(JSON.encode!(%{revoked: true, invitation_id: invitation_id}))

              {:reply, response, frame}

            {:error, _changeset} ->
              {:error, Hermes.MCP.Error.execution("Failed to revoke invitation"), frame}
          end
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
