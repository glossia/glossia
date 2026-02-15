defmodule Glossia.Admin.MCP.GetUserTool do
  @moduledoc "Get details about a specific user by email or handle (super admin only)."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Admin.MCP.Authorization, as: Auth
  alias Glossia.Accounts
  alias Glossia.Accounts.User
  alias Glossia.Repo
  alias Hermes.Server.Response

  import Ecto.Query

  schema do
    field :email, :string, description: "User email address."
    field :handle, :string, description: "User account handle."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, _admin} <- Auth.current_user(frame) do
      user = find_user(params)

      case user do
        nil ->
          {:error, Hermes.MCP.Error.execution("User not found"), frame}

        %User{} = u ->
          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                id: u.id,
                email: u.email,
                name: u.name,
                handle: u.account.handle,
                has_access: u.has_access,
                super_admin: u.super_admin,
                avatar_url: u.avatar_url,
                inserted_at: u.inserted_at
              })
            )

          {:reply, response, frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end

  defp find_user(%{"email" => email}) when is_binary(email) do
    User |> where(email: ^email) |> preload(:account) |> Repo.one()
  end

  defp find_user(%{"handle" => handle}) when is_binary(handle) do
    case Accounts.get_account_by_handle(handle) do
      nil -> nil
      account -> User |> where(account_id: ^account.id) |> preload(:account) |> Repo.one()
    end
  end

  defp find_user(_), do: nil
end
