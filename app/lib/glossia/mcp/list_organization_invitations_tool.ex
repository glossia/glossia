defmodule Glossia.MCP.ListOrganizationInvitationsTool do
  @moduledoc "List pending invitations for an organization."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Organizations
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Organization handle."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]

    with {:ok, user, account} <- Auth.fetch_organization_context(frame, handle),
         :ok <- Auth.authorize(frame, :members_read, user, account) do
      org = Organizations.get_organization_for_account(account)
      invitations = Organizations.list_pending_invitations(org)

      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(
            Enum.map(invitations, fn inv ->
              %{
                id: inv.id,
                email: inv.email,
                role: inv.role,
                status: inv.status,
                expires_at: inv.expires_at
              }
            end)
          )
        )

      {:reply, response, frame}
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
