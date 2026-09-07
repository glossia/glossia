defmodule Glossia.MCP.ListAccountsTool do
  @moduledoc "List organization handles the authenticated user has access to, including the personal organization."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
  end

  @impl true
  def execute(_params, frame) do
    with {:ok, user} <- Auth.current_user(frame),
         :ok <- Auth.authorize(frame, :account_read, user) do
      {:ok, {accounts, _meta}} = Accounts.list_user_accounts(user)

      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(
            Enum.map(accounts, fn account ->
              %{
                handle: account.handle,
                visibility: account.visibility
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
