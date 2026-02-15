defmodule Glossia.Admin.MCP.Authorization do
  @moduledoc false

  alias Glossia.Accounts.User
  alias Hermes.MCP.Error

  @spec current_user(Hermes.Server.Frame.t()) :: {:ok, %User{}} | {:error, Error.t()}
  def current_user(frame) do
    case frame.assigns[:current_user] do
      %User{super_admin: true} = user -> {:ok, user}
      %User{} -> {:error, Error.execution("Super admin access required")}
      _ -> {:error, Error.execution("Authentication required")}
    end
  end
end
