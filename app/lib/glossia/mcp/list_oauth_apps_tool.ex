defmodule Glossia.MCP.ListOAuthAppsTool do
  @moduledoc "List OAuth applications for an account."

  use Hermes.Server.Component, type: :tool

  alias Glossia.DeveloperTokens
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Account handle"
  end

  @impl true
  def execute(%{"handle" => handle}, frame) do
    with {:ok, user, account} <- Auth.fetch_context(frame, handle),
         :ok <- Auth.authorize(frame, :api_credentials_read, user, account) do
      {:ok, {apps, _meta}} = DeveloperTokens.list_oauth_applications(account)

      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(
            Enum.map(apps, fn a ->
              %{
                id: a.id,
                name: a.name,
                description: a.description,
                homepage_url: a.homepage_url,
                client_id: a.boruta_client_id,
                inserted_at: a.inserted_at
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
