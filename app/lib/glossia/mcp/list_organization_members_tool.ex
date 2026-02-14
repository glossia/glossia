defmodule Glossia.MCP.ListOrganizationMembersTool do
  @moduledoc "List members of an organization."

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
              members = Accounts.list_members(org)

              response =
                Response.tool()
                |> Response.text(
                  Jason.encode!(
                    Enum.map(members, fn membership ->
                      %{
                        handle: membership.user.account.handle,
                        email: membership.user.email,
                        role: membership.role,
                        joined_at: membership.inserted_at
                      }
                    end)
                  )
                )

              {:reply, response, frame}

            {:error, :unauthorized} ->
              {:error, Error.execution("Not authorized to list members of '#{handle}'"), frame}
          end
      end
    end
  end
end
