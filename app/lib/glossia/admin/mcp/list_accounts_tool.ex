defmodule Glossia.Admin.MCP.ListAccountsTool do
  @moduledoc "List all accounts in the system (super admin only)."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Admin.MCP.Authorization, as: Auth
  alias Glossia.Accounts.Account
  alias Glossia.Repo
  alias Hermes.Server.Response

  import Ecto.Query

  schema do
    field :page, :integer, description: "Page number (1-based). Defaults to 1."
    field :page_size, :integer, description: "Items per page (max 100). Defaults to 50."
    field :type, :string, description: "Filter by account type: 'user' or 'organization'."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, _user} <- Auth.current_user(frame) do
      page = Map.get(params, "page", 1)
      page_size = min(Map.get(params, "page_size", 50), 100)

      query = Account |> order_by(desc: :inserted_at)

      query =
        case params["type"] do
          type when type in ["user", "organization"] -> where(query, type: ^type)
          _ -> query
        end

      accounts =
        query
        |> limit(^page_size)
        |> offset(^(max(page - 1, 0) * page_size))
        |> Repo.all()

      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(
            Enum.map(accounts, fn a ->
              %{
                id: a.id,
                handle: a.handle,
                type: a.type,
                visibility: a.visibility,
                has_access: a.has_access,
                inserted_at: a.inserted_at
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
