defmodule Glossia.MCP.ListOrganizationMembersTool do
  @moduledoc "List members of an organization."

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

    with {:ok, user} <- Auth.current_user(frame),
         {:ok, account} <- Auth.fetch_organization_account(handle),
         :ok <- Auth.authorize(frame, :members_read, user, account) do
      org = Organizations.get_organization_for_account(account)
      members = Organizations.list_members(org)

      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(
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
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
