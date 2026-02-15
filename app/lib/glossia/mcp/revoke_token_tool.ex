defmodule Glossia.MCP.RevokeTokenTool do
  @moduledoc "Revoke a personal access token."

  use Hermes.Server.Component, type: :tool

  alias Glossia.DeveloperTokens
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Account handle"
    field :token_id, {:required, :string}, description: "Token ID to revoke"
  end

  @impl true
  def execute(%{"handle" => handle, "token_id" => token_id}, frame) do
    with {:ok, user} <- Auth.current_user(frame),
         {:ok, account} <- Auth.fetch_account(handle),
         :ok <- Auth.authorize(frame, :api_credentials_write, user, account) do
      case DeveloperTokens.revoke_personal_access_token(token_id, account.id) do
        {:ok, token} ->
          Glossia.Auditing.record("token.revoked", account, user,
            resource_type: "personal_access_token",
            resource_id: to_string(token.id),
            summary: "Revoked personal access token \"#{token.name}\""
          )

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
