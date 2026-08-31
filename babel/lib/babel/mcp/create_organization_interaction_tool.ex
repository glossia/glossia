defmodule Babel.MCP.CreateOrganizationInteractionTool do
  @moduledoc "Add a dated research, outreach, or meeting entry to an organization timeline. It never sends email."

  use Hermes.Server.Component, type: :tool

  alias Babel.MCP.Authorization
  alias Babel.MCP.OrganizationInteractionSerializer
  alias Babel.Organizations
  alias Babel.Organizations.Interaction
  alias Hermes.MCP.Error
  alias Hermes.Server.Response

  @kinds Interaction.kinds()

  schema do
    field :organization_id, :integer, required: true, description: "Organization identifier."
    field :kind, :string, required: true, enum: @kinds, description: "Type of timeline event."
    field :summary, :string, required: true, description: "Concise timeline event title."
    field :body, :string, description: "Optional detail or reviewed draft."
    field :source_url, :string, description: "Optional secure web address supporting the event."

    field :occurred_at, :string,
      description: "Optional event time in ISO 8601 format. Defaults to the current time."
  end

  @impl true
  def execute(%{organization_id: organization_id} = params, frame) do
    case Authorization.authorize_write(frame) do
      :ok -> create_interaction(organization_id, Map.delete(params, :organization_id), frame)
      {:error, error} -> {:error, error, frame}
    end
  end

  defp create_interaction(organization_id, attributes, frame) do
    case Organizations.get_organization(organization_id) do
      nil ->
        {:error, Error.execution("Organization not found"), frame}

      organization ->
        attributes = Map.put_new(attributes, :occurred_at, DateTime.utc_now(:second))

        case Organizations.create_interaction(organization, attributes) do
          {:ok, interaction} ->
            response =
              Response.tool()
              |> Response.structured(%{
                interaction: OrganizationInteractionSerializer.serialize(interaction)
              })

            {:reply, response, frame}

          {:error, changeset} ->
            {:error, Error.execution("Could not add interaction: #{format_errors(changeset)}"),
             frame}
        end
    end
  end

  defp format_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, _options} -> message end)
    |> inspect()
  end
end
