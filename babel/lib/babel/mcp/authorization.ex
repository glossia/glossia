defmodule Babel.MCP.Authorization do
  @moduledoc false

  alias Babel.Accounts.Account
  alias Hermes.MCP.Error

  @operations_read_scope "operations:read"
  @operations_write_scope "operations:write"

  def authorize(frame), do: authorize(frame, @operations_read_scope)

  def authorize_write(frame), do: authorize(frame, @operations_write_scope)

  defp authorize(frame, required_scope) do
    with %Account{} <- frame.assigns[:current_account],
         true <- required_scope in scopes(frame) do
      :ok
    else
      false ->
        {:error, Error.execution("Insufficient scope (required: #{required_scope})")}

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
