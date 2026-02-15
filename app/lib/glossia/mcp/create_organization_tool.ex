defmodule Glossia.MCP.CreateOrganizationTool do
  @moduledoc "Create a new organization. The authenticated user becomes the admin."

  use Hermes.Server.Component, type: :tool
  use GlossiaWeb, :verified_routes

  alias Glossia.ChangesetErrors
  alias Glossia.Auditing
  alias Glossia.Organizations
  alias Glossia.MCP.Authorization, as: Auth
  alias Hermes.Server.Response

  schema do
    field :handle, {:required, :string},
      description:
        "Organization handle. Lowercase letters, numbers, and hyphens only. Must start with a letter."

    field :name, :string,
      description: "Display name for the organization. Defaults to the handle if omitted."
  end

  @impl true
  def execute(params, frame) do
    with {:ok, user} <- Auth.current_user(frame),
         :ok <- Auth.authorize(frame, :organization_write, user) do
      handle = params["handle"]
      name = params["name"] || handle

      case Organizations.create_organization(user, %{"handle" => handle, "name" => name}) do
        {:ok, %{account: account, organization: org}} ->
          Auditing.record("organization.created", account, user,
            resource_type: "organization",
            resource_id: to_string(org.id),
            resource_path: ~p"/#{account.handle}",
            summary: "Created organization \"#{account.handle}\""
          )

          response =
            Response.tool()
            |> Response.text(
              JSON.encode!(%{handle: account.handle, name: org.name, type: "organization"})
            )

          {:reply, response, frame}

        {:error, :account, changeset, _} ->
          errors = ChangesetErrors.to_inline_string(changeset)
          {:error, Hermes.MCP.Error.execution("Validation failed: #{errors}"), frame}

        {:error, _step, changeset, _} ->
          errors = ChangesetErrors.to_inline_string(changeset)
          {:error, Hermes.MCP.Error.execution("Failed to create organization: #{errors}"), frame}
      end
    else
      {:error, error} -> {:error, error, frame}
    end
  end
end
