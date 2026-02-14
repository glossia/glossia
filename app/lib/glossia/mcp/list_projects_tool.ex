defmodule Glossia.MCP.ListProjectsTool do
  @moduledoc "List projects for a given account."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Glossia.Accounts.Account
  alias Glossia.Repo
  alias Hermes.Server.Response
  alias Hermes.MCP.Error
  import Ecto.Query

  schema do
    field :handle, {:required, :string}, description: "Account handle to list projects for."
  end

  @impl true
  def execute(params, frame) do
    user = frame.assigns[:current_user]

    unless user do
      {:error, Error.execution("Authentication required"), frame}
    else
      handle = params["handle"]

      case Account |> where(handle: ^handle) |> Repo.one() do
        nil ->
          {:error, Error.execution("Account '#{handle}' not found"), frame}

        account ->
          case Glossia.Policy.authorize(:project_read, user, account) do
            :ok ->
              {:ok, {projects, _meta}} = Accounts.list_projects(account)

              response =
                Response.tool()
                |> Response.text(
                  Jason.encode!(
                    Enum.map(projects, fn project ->
                      %{handle: project.handle, name: project.name}
                    end)
                  )
                )

              {:reply, response, frame}

            {:error, :unauthorized} ->
              {:error, Error.execution("Not authorized to list projects for '#{handle}'"), frame}
          end
      end
    end
  end
end
