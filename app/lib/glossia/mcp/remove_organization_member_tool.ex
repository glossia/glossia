defmodule Glossia.MCP.RemoveOrganizationMemberTool do
  @moduledoc "Remove a member from an organization."

  use Hermes.Server.Component, type: :tool
  use GlossiaWeb, :verified_routes

  alias Glossia.Accounts
  alias Glossia.Auditing
  alias Glossia.Organizations
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Organization handle."
    field :user_handle, {:required, :string}, description: "Handle of the user to remove."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]
    user_handle = params["user_handle"]

    with {:ok, user} <- Auth.current_user(frame),
         {:ok, account} <- Auth.fetch_organization_account(handle),
         :ok <- Auth.authorize(frame, :members_write, user, account) do
      org = Organizations.get_organization_for_account(account)

      case Accounts.get_user_by_handle(user_handle) do
        nil ->
          {:error, Hermes.MCP.Error.execution("User '#{user_handle}' not found"), frame}

        target_user ->
          if Organizations.sole_admin?(org, target_user) do
            {:error,
             Hermes.MCP.Error.execution("Cannot remove the only admin of the organization"),
             frame}
          else
            Organizations.remove_member(org, target_user)

            Auditing.record("member.removed", account, user,
              resource_type: "member",
              resource_id: to_string(target_user.id),
              resource_path: ~p"/#{account.handle}/members",
              summary: "Removed #{user_handle} from organization"
            )

            response =
              Response.tool()
              |> Response.text(JSON.encode!(%{removed: true, user_handle: user_handle}))

            {:reply, response, frame}
          end
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
