defmodule Glossia.MCP.GetOrganizationTool do
  @moduledoc "Get details of an organization by handle."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Glossia.Accounts.Account
  alias Glossia.Repo
  alias Hermes.Server.Response
  alias Hermes.MCP.Error
  import Ecto.Query

  schema do
    field :handle, {:required, :string}, description: "Organization handle."
  end

  @impl true
  def execute(params, frame) do
    user = frame.assigns[:current_user]

    unless user do
      {:error, Error.execution("Authentication required"), frame}
    else
      handle = params["handle"]

      case Account |> where(handle: ^handle, type: "organization") |> Repo.one() do
        nil ->
          {:error, Error.execution("Organization '#{handle}' not found"), frame}

        account ->
          case Glossia.Policy.authorize(:org_read, user, account) do
            :ok ->
              org = Accounts.get_organization_for_account(account)

              response =
                Response.tool()
                |> Response.text(
                  Jason.encode!(%{
                    handle: org.account.handle,
                    name: org.name,
                    type: "organization",
                    visibility: org.account.visibility
                  })
                )

              {:reply, response, frame}

            {:error, :unauthorized} ->
              {:error, Error.execution("Not authorized to view '#{handle}'"), frame}
          end
      end
    end
  end
end
