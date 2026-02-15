defmodule Glossia.MCP.ListTokensTool do
  @moduledoc "List personal access tokens for an account."

  use Hermes.Server.Component, type: :tool

  alias Glossia.DeveloperTokens
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Account handle"
  end

  @impl true
  def execute(%{"handle" => handle}, frame) do
    with {:ok, user} <- Auth.current_user(frame),
         {:ok, account} <- Auth.fetch_account(handle),
         :ok <- Auth.authorize(frame, :api_credentials_read, user, account) do
      {:ok, {tokens, _meta}} = DeveloperTokens.list_personal_access_tokens(account)

      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(
            Enum.map(tokens, fn t ->
              %{
                id: t.id,
                name: t.name,
                token_prefix: t.token_prefix,
                scope: t.scope,
                expires_at: t.expires_at,
                last_used_at: t.last_used_at,
                inserted_at: t.inserted_at
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
