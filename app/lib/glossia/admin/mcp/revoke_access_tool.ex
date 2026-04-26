defmodule Glossia.Admin.MCP.RevokeAccessTool do
  @moduledoc "Revoke product access from a user by email (super admin only)."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Admin.MCP.Authorization, as: Auth
  alias Glossia.Accounts
  alias Glossia.Events
  alias Hermes.Server.Response

  schema do
    field :email, {:required, :string}, description: "Email of the user to revoke access from."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, admin} <- Auth.current_user(frame) do
      case Accounts.revoke_access(params["email"]) do
        {:ok, user} ->
          Events.emit("admin.access_revoked", admin.account, admin,
            resource_type: "user",
            resource_id: to_string(user.id),
            resource_path: "/admin/users",
            summary: "Revoked access from #{user.email}"
          )

          response =
            Response.tool()
            |> Response.text(JSON.encode!(%{email: user.email, has_access: false}))

          {:reply, response, frame}

        {:error, :not_found} ->
          {:error, Hermes.MCP.Error.execution("User not found"), frame}

        {:error, _changeset} ->
          {:error, Hermes.MCP.Error.execution("Failed to revoke access"), frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
