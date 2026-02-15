defmodule Glossia.MCP.GetOrganizationTool do
  @moduledoc "Get details of an organization by handle."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Organizations
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Organization handle."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]

    with {:ok, user} <- Auth.current_user(frame),
         {:ok, account} <- Auth.fetch_organization_account(handle),
         :ok <- Auth.authorize(frame, :organization_read, user, account) do
      org = Organizations.get_organization_for_account(account)

      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(%{
            handle: org.account.handle,
            name: org.name,
            type: "organization",
            visibility: org.account.visibility
          })
        )

      {:reply, response, frame}
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
