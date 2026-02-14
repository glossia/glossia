defmodule Glossia.MCP.CreateOrganizationTool do
  @moduledoc "Create a new organization. The authenticated user becomes the admin."

  use Hermes.Server.Component, type: :tool

  alias Glossia.Accounts
  alias Hermes.Server.Response
  alias Hermes.MCP.Error

  schema do
    field :handle, {:required, :string},
      description:
        "Organization handle. Lowercase letters, numbers, and hyphens only. Must start with a letter."

    field :name, :string,
      description: "Display name for the organization. Defaults to the handle if omitted."
  end

  @impl true
  def execute(params, frame) do
    user = frame.assigns[:current_user]

    unless user do
      {:error, Error.execution("Authentication required"), frame}
    else
      handle = params["handle"]
      name = params["name"] || handle

      case Accounts.create_organization(user, %{"handle" => handle, "name" => name}) do
        {:ok, %{account: account, organization: org}} ->
          response =
            Response.tool()
            |> Response.text(
              Jason.encode!(%{handle: account.handle, name: org.name, type: "organization"})
            )

          {:reply, response, frame}

        {:error, :account, changeset, _} ->
          errors = format_errors(changeset)
          {:error, Error.execution("Validation failed: #{errors}"), frame}

        {:error, _step, changeset, _} ->
          errors = format_errors(changeset)
          {:error, Error.execution("Failed to create organization: #{errors}"), frame}
      end
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map_join(", ", fn {field, msgs} -> "#{field}: #{Enum.join(msgs, ", ")}" end)
  end
end
