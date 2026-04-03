defmodule Glossia.MCP.CreateTokenTool do
  @moduledoc "Create an account token for an account."

  use Hermes.Server.Component, type: :tool

  alias Glossia.DeveloperTokens
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Account handle"
    field :name, {:required, :string}, description: "Token name"
    field :description, :string, description: "Token description"
    field :scope, :string, description: "Space-separated scopes"
    field :expires_in_days, :number, description: "Expiration in days (omit for no expiration)"
  end

  @impl true
  def execute(%{"handle" => handle, "name" => name} = params, frame) do
    with {:ok, user, account} <- Auth.fetch_context(frame, handle),
         :ok <- Auth.authorize(frame, :api_credentials_write, user, account) do
      expires_at =
        case params["expires_in_days"] do
          days when is_number(days) and days > 0 ->
            DateTime.add(DateTime.utc_now(), trunc(days), :day)

          _ ->
            nil
        end

      attrs = %{
        "name" => name,
        "description" => params["description"] || "",
        "scope" => params["scope"] || "",
        "expires_at" => expires_at
      }

      case DeveloperTokens.create_account_token(account, user, attrs) do
        {:ok, %{token: token, plain_token: plain_token}} ->
          Glossia.Events.emit("token.created", account, user,
            resource_type: "account_token",
            resource_id: to_string(token.id),
            resource_path: "/#{account.handle}/-/settings/tokens",
            summary: "Created account token \"#{token.name}\""
          )

          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                id: token.id,
                name: token.name,
                plain_token: plain_token,
                scope: token.scope,
                expires_at: token.expires_at
              })
            )

          {:reply, response, frame}

        {:error, _changeset} ->
          {:error, Hermes.MCP.Error.execution("Could not create token"), frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
