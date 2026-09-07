defmodule Glossia.MCP.ListOrganizationsTool do
  @moduledoc "List organizations the authenticated user belongs to."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Organizations
  alias Glossia.MCP.Authorization, as: Auth
  alias Glossia.Repo
  alias Hermes.Server.Response

  schema do
  end

  @impl true
  def execute(_params, frame) do
    with {:ok, user} <- Auth.current_user(frame),
         :ok <- Auth.authorize(frame, :organization_read, user) do
      orgs = Organizations.list_user_organizations(user)

      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(
            Enum.map(orgs, fn org ->
              org = Repo.preload(org, :account)
              %{handle: org.account.handle, name: org.name, visibility: org.account.visibility}
            end)
          )
        )

      {:reply, response, frame}
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
