defmodule Glossia.MCP.RevokeOrganizationInvitationTool do
  @moduledoc "Revoke a pending invitation for an organization."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Glossia.Accounts.Account
  alias Glossia.Repo
  alias Hermes.Server.Response
  alias Hermes.MCP.Error
  import Ecto.Query

  schema do
    field :handle, {:required, :string}, description: "Organization handle."
    field :invitation_id, {:required, :string}, description: "ID of the invitation to revoke."
  end

  @impl true
  def execute(params, frame) do
    user = frame.assigns[:current_user]

    unless user do
      {:error, Error.execution("Authentication required"), frame}
    else
      handle = params["handle"]
      invitation_id = params["invitation_id"]

      case Account |> where(handle: ^handle, type: "organization") |> Repo.one() do
        nil ->
          {:error, Error.execution("Organization '#{handle}' not found"), frame}

        account ->
          case Glossia.Policy.authorize(:members_write, user, account) do
            :ok ->
              org = Accounts.get_organization_for_account(account)

              case Accounts.get_invitation(org, invitation_id) do
                nil ->
                  {:error, Error.execution("Invitation not found"), frame}

                invitation ->
                  case Accounts.revoke_invitation(invitation) do
                    {:ok, _} ->
                      response =
                        Response.tool()
                        |> Response.text(
                          Jason.encode!(%{revoked: true, invitation_id: invitation_id})
                        )

                      {:reply, response, frame}

                    {:error, _changeset} ->
                      {:error, Error.execution("Failed to revoke invitation"), frame}
                  end
              end

            {:error, :unauthorized} ->
              {:error, Error.execution("Not authorized to manage invitations for '#{handle}'"),
               frame}
          end
      end
    end
  end
end
