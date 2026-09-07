defmodule Glossia.MCP.RevokeTokenTool do
  @moduledoc "Revoke an account token."

  use Hermes.Server.Component, type: :tool

  alias Glossia.AccountTokens
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Account handle"
    field :token_id, {:required, :string}, description: "Token ID to revoke"
  end

  @impl true
  def execute(%{"handle" => handle, "token_id" => token_id}, frame) do
    with {:ok, user, account} <- Auth.fetch_context(frame, handle),
         :ok <- Auth.authorize(frame, :api_credentials_write, user, account) do
      case AccountTokens.revoke_account_token(token_id, account.id, actor: user, via: :mcp) do
        {:ok, token} ->
          response =
            Response.tool()
            |> Response.text(JSON.encode!(%{status: "revoked", id: token.id}))

          {:reply, response, frame}

        {:error, :not_found} ->
          {:error, Hermes.MCP.Error.execution("Token not found"), frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
