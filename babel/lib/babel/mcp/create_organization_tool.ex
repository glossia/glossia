defmodule Babel.MCP.CreateOrganizationTool do
  @moduledoc "Create an organization. It does not send outreach or contact anyone."

  use Hermes.Server.Component, type: :tool

  alias Babel.MCP.Authorization
  alias Babel.MCP.OrganizationSerializer
  alias Babel.Organizations
  alias Babel.Organizations.Organization
  alias Hermes.MCP.Error
  alias Hermes.Server.Response

  @states Organization.states()

  schema do
    field :name, :string, required: true, description: "Company name."
    field :website_url, :string, required: true, description: "Company secure website address."

    field :origin_url, :string,
      description: "Public secure web address that led to this organization."

    field :state, :string,
      enum: @states,
      description: "Engagement state. Defaults to researching."

    field :translation_tool, :string,
      description: "Known translation tool, if publicly evidenced."

    field :glossia_organization_id, :string,
      description: "Optional Glossia organization identifier for usage data."

    field :notes, :string, description: "Internal research notes."
  end

  @impl true
  def execute(params, frame) do
    case Authorization.authorize_write(frame) do
      :ok ->
        case Organizations.create_organization(params) do
          {:ok, organization} ->
            response =
              Response.tool()
              |> Response.structured(%{
                organization: OrganizationSerializer.serialize(organization)
              })

            {:reply, response, frame}

          {:error, changeset} ->
            {:error,
             Error.execution("Could not create organization: #{format_errors(changeset)}"), frame}
        end

      {:error, error} ->
        {:error, error, frame}
    end
  end

  defp format_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, _options} -> message end)
    |> inspect()
  end
end
