defmodule Glossia.MCP.InviteOrganizationMemberTool do
  @moduledoc "Invite a user to an organization by email."

  use Hermes.Server.Component, type: :tool

  alias Glossia.ChangesetErrors
  alias Glossia.Organizations
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Organization handle."
    field :email, {:required, :string}, description: "Email address to invite."

    field :role, :string,
      description: "Role for the invitee (admin, member, linguist). Defaults to member."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]

    with {:ok, user} <- Auth.current_user(frame),
         {:ok, account} <- Auth.fetch_organization_account(handle),
         :ok <- Auth.authorize(frame, :members_write, user, account) do
      org = Organizations.get_organization_for_account(account)

      case Organizations.create_invitation(org, user, params) do
        {:ok, invitation} ->
          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                id: invitation.id,
                email: invitation.email,
                role: invitation.role,
                status: invitation.status,
                expires_at: invitation.expires_at
              })
            )

          {:reply, response, frame}

        {:error, :already_member} ->
          {:error, Hermes.MCP.Error.execution("User is already a member of this organization"),
           frame}

        {:error, :already_invited} ->
          {:error,
           Hermes.MCP.Error.execution("A pending invitation already exists for this email"),
           frame}

        {:error, changeset} ->
          errors = ChangesetErrors.to_inline_string(changeset)
          {:error, Hermes.MCP.Error.execution("Invitation failed: #{errors}"), frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
