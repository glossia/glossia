defmodule Glossia.MCP.ListOrganizationsTool do
  @moduledoc "List organizations the authenticated user belongs to."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Glossia.Repo
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
      orgs = Accounts.list_user_organizations(user)

      response =
        Response.tool()
        |> Response.text(
          Jason.encode!(
            Enum.map(orgs, fn org ->
              org = Repo.preload(org, :account)
              %{handle: org.account.handle, name: org.name, visibility: org.account.visibility}
            end)
          )
        )

      {:reply, response, frame}
    end
  end
end
