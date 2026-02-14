defmodule Glossia.MCP.ListAccountsTool do
  @moduledoc "List accounts the authenticated user has access to (personal account and organizations)."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Hermes.Server.Response
  alias Hermes.MCP.Error

  schema do
  end

  @impl true
  def execute(_params, frame) do
    user = frame.assigns[:current_user]

    unless user do
      {:error, Error.execution("Authentication required"), frame}
    else
      {:ok, {accounts, _meta}} = Accounts.list_user_accounts(user)

      response =
        Response.tool()
        |> Response.text(
          Jason.encode!(
            Enum.map(accounts, fn account ->
              %{
                handle: account.handle,
                type: account.type,
                visibility: account.visibility
              }
            end)
          )
        )

      {:reply, response, frame}
    end
  end
end
