defmodule Babel.MCP.Authorization do
  @moduledoc false

  alias Babel.Accounts.Account
  alias Hermes.MCP.Error

  @operations_read_scope "operations:read"

  def authorize(frame) do
    with %Account{} <- frame.assigns[:current_account],
         true <- @operations_read_scope in scopes(frame) do
      :ok
    else
      false ->
        {:error, Error.execution("Insufficient scope (required: #{@operations_read_scope})")}

      _ ->
        {:error, Error.execution("Authentication required")}
    end
  end

  defp scopes(frame) do
    case frame.assigns[:scopes] do
      scopes when is_list(scopes) -> scopes
      _ -> []
    end
  end
end
