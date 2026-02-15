defmodule Glossia.Admin.MCP.SetSuperAdminTool do
  @moduledoc "Grant or revoke super admin status for a user (super admin only)."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Admin.MCP.Authorization, as: Auth
  alias Glossia.Accounts
  alias Glossia.Accounts.User
  alias Glossia.Auditing
  alias Glossia.Repo
  alias Hermes.Server.Response

  import Ecto.Query

  schema do
    field :email, {:required, :string}, description: "Email of the user."

    field :super_admin, {:required, :boolean},
      description: "Set to true to grant super admin, false to revoke."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, admin} <- Auth.current_user(frame) do
      email = params["email"]
      value = params["super_admin"]

      case User |> where(email: ^email) |> Repo.one() do
        nil ->
          {:error, Hermes.MCP.Error.execution("User not found"), frame}

        user ->
          case Accounts.set_super_admin(user.id, value) do
            {:ok, updated} ->
              event =
                if(value, do: "admin.super_admin_granted", else: "admin.super_admin_revoked")

              Auditing.record(event, admin.account, admin,
                resource_type: "user",
                resource_id: to_string(updated.id),
                summary: "Set super_admin=#{value} for #{updated.email}"
              )

              response =
                Response.tool()
                |> Response.text(
                  JSON.encode!(%{email: updated.email, super_admin: updated.super_admin})
                )

              {:reply, response, frame}

            {:error, _} ->
              {:error, Hermes.MCP.Error.execution("Failed to update super admin status"), frame}
          end
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
