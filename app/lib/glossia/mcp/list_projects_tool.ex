defmodule Glossia.MCP.ListProjectsTool do
  @moduledoc "List projects for a given account."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Projects
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string}, description: "Account handle to list projects for."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]

    with {:ok, user, account} <- Auth.fetch_context(frame, handle),
         :ok <- Auth.authorize(frame, :project_read, user, account) do
      {:ok, {projects, _meta}} = Projects.list_projects(account)

      response =
        Response.tool()
        |> Response.text(
          JSON.encode!(
            Enum.map(projects, fn project ->
              %{handle: project.handle, name: project.name}
            end)
          )
        )

      {:reply, response, frame}
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
