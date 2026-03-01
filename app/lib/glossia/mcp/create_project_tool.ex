defmodule Glossia.MCP.CreateProjectTool do
  @moduledoc "Create a new project for an account."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Auditing
  alias Glossia.ChangesetErrors
  alias Glossia.Projects
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string},
      description: "Account handle to create the project under."

    field :project_handle, {:required, :string},
      description:
        "URL-friendly project identifier (lowercase letters, numbers, hyphens; 2-39 chars)."

    field :name, {:required, :string}, description: "Display name for the project."
  end

  @impl true
  def execute(params, frame) do
    handle = params["handle"]

    with {:ok, user} <- Auth.current_user(frame),
         {:ok, account} <- Auth.fetch_account(handle),
         :ok <- Auth.authorize(frame, :project_write, user, account) do
      attrs = %{
        handle: params["project_handle"],
        name: params["name"]
      }

      case Projects.create_project(account, attrs) do
        {:ok, project} ->
          Auditing.record("project.created", account, user,
            resource_type: "project",
            resource_id: to_string(project.id),
            resource_path: "/#{handle}/#{project.handle}",
            summary: "Created project #{project.handle} via MCP"
          )

          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{
                handle: project.handle,
                name: project.name,
                inserted_at: project.inserted_at
              })
            )

          {:reply, response, frame}

        {:error, changeset} ->
          errors = ChangesetErrors.to_inline_string(changeset)
          {:error, Hermes.MCP.Error.execution("Validation failed: #{errors}"), frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
