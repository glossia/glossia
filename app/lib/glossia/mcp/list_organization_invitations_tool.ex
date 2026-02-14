defmodule Glossia.MCP.ListOrganizationInvitationsTool do
  @moduledoc "List pending invitations for an organization."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Glossia.Accounts.Account
  alias Glossia.Repo
  alias Hermes.Server.Response
  alias Hermes.MCP.Error
  import Ecto.Query

  schema do
    field :handle, {:required, :string}, description: "Organization handle."
  end

  @impl true
  def execute(params, frame) do
    user = frame.assigns[:current_user]

    unless user do
      {:error, Error.execution("Authentication required"), frame}
    else
      handle = params["handle"]

      case Account |> where(handle: ^handle, type: "organization") |> Repo.one() do
        nil ->
          {:error, Error.execution("Organization '#{handle}' not found"), frame}

        account ->
          case Glossia.Policy.authorize(:members_read, user, account) do
            :ok ->
              org = Accounts.get_organization_for_account(account)
              invitations = Accounts.list_pending_invitations(org)

              response =
                Response.tool()
                |> Response.text(
                  Jason.encode!(
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

            {:error, :unauthorized} ->
              {:error, Error.execution("Not authorized to list invitations for '#{handle}'"),
               frame}
          end
      end
    end
  end
end
