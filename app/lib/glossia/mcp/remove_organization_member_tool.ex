defmodule Glossia.MCP.RemoveOrganizationMemberTool do
  @moduledoc "Remove a member from an organization."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Glossia.Accounts.Account
  alias Glossia.Repo
  alias Hermes.Server.Response
  alias Hermes.MCP.Error
  import Ecto.Query

  schema do
    field :handle, {:required, :string}, description: "Organization handle."
    field :user_handle, {:required, :string}, description: "Handle of the user to remove."
  end

  @impl true
  def execute(params, frame) do
    user = frame.assigns[:current_user]

    unless user do
      {:error, Error.execution("Authentication required"), frame}
    else
      handle = params["handle"]
      user_handle = params["user_handle"]

      case Account |> where(handle: ^handle, type: "organization") |> Repo.one() do
        nil ->
          {:error, Error.execution("Organization '#{handle}' not found"), frame}

        account ->
          case Glossia.Policy.authorize(:members_write, user, account) do
            :ok ->
              org = Accounts.get_organization_for_account(account)

              case Accounts.get_user_by_handle(user_handle) do
                nil ->
                  {:error, Error.execution("User '#{user_handle}' not found"), frame}

                target_user ->
                  if Accounts.sole_admin?(org, target_user) do
                    {:error, Error.execution("Cannot remove the only admin of the organization"),
                     frame}
                  else
                    Accounts.remove_member(org, target_user)

                    response =
                      Response.tool()
                      |> Response.text(Jason.encode!(%{removed: true, user_handle: user_handle}))

                    {:reply, response, frame}
                  end
              end

            {:error, :unauthorized} ->
              {:error, Error.execution("Not authorized to manage members of '#{handle}'"), frame}
          end
      end
    end
  end
end
