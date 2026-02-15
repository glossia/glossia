defmodule Glossia.Admin.MCP.GrantAccessTool do
  @moduledoc "Grant product access to a user by email (super admin only)."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Admin.MCP.Authorization, as: Auth
  alias Glossia.Accounts
  alias Hermes.Server.Response

  schema do
    field :email, {:required, :string}, description: "Email of the user to grant access to."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, _admin} <- Auth.current_user(frame) do
      case Accounts.grant_access(params["email"]) do
        {:ok, user} ->
          response =
            Response.tool()
            |> Response.text(JSON.encode!(%{email: user.email, has_access: true}))

          {:reply, response, frame}

        {:error, :not_found} ->
          {:error, Hermes.MCP.Error.execution("User not found"), frame}

        {:error, _changeset} ->
          {:error, Hermes.MCP.Error.execution("Failed to grant access"), frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
