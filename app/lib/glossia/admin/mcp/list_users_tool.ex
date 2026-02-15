defmodule Glossia.Admin.MCP.ListUsersTool do
  @moduledoc "List all users in the system (super admin only)."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Admin.MCP.Authorization, as: Auth
  alias Glossia.Accounts.User
  alias Glossia.Repo
  alias Hermes.Server.Response

  import Ecto.Query

  schema do
    field :page, :integer, description: "Page number (1-based). Defaults to 1."
    field :page_size, :integer, description: "Items per page (max 100). Defaults to 50."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, _user} <- Auth.current_user(frame) do
      page = Map.get(params, "page", 1)
      page_size = min(Map.get(params, "page_size", 50), 100)

      users =
        User
        |> preload(:account)
        |> order_by(desc: :inserted_at)
        |> limit(^page_size)
        |> offset(^(max(page - 1, 0) * page_size))
        |> Repo.all()

      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(
            Enum.map(users, fn u ->
              %{
                id: u.id,
                email: u.email,
                name: u.name,
                handle: u.account.handle,
                has_access: u.has_access,
                super_admin: u.super_admin,
                inserted_at: u.inserted_at
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
