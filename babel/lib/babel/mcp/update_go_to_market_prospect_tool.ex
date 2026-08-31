defmodule Babel.MCP.UpdateGoToMarketProspectTool do
  @moduledoc "Update a public-source prospect record or its reviewable draft. This tool never sends email."

  use Hermes.Server.Component, type: :tool

  alias Babel.GoToMarket
  alias Babel.GoToMarket.Prospect
  alias Babel.MCP.Authorization
  alias Babel.MCP.GoToMarketProspectSerializer
  alias Hermes.MCP.Error
  alias Hermes.Server.Response

  @statuses Prospect.statuses()

  schema do
    field :id, :integer, required: true, description: "Prospect identifier."
    field :company, :string, description: "Company name."
    field :website_url, :string, description: "Company secure website address."

    field :translation_tool, :string,
      description: "Known translation tool, if publicly evidenced."

    field :source_title, :string, description: "Title of the public research source."
    field :source_url, :string, description: "Secure web address for the public research source."
    field :evidence, :string, description: "Observed localization or workflow signal."
    field :contact_name, :string, description: "Publicly named contact, if current and relevant."
    field :contact_role, :string, description: "The contact's publicly stated role."

    field :contact_profile_url, :string,
      description: "Secure web address for the public contact profile."

    field :status, :string, enum: @statuses, description: "Research stage."

    field :outreach_angle, :string,
      description: "Specific, low-pressure reason to start a conversation."

    field :intro_email_draft, :string,
      description: "Reviewable email draft. It is never sent by this tool."

    field :next_step, :string,
      description: "Concrete verification or review step before outreach."

    field :organization_id, :integer, description: "Optional organization identifier."
  end

  @impl true
  def execute(%{id: id} = params, frame) do
    case Authorization.authorize_write(frame) do
      :ok -> update_prospect(id, Map.delete(params, :id), frame)
      {:error, error} -> {:error, error, frame}
    end
  end

  defp update_prospect(id, attributes, frame) do
    case GoToMarket.get_prospect(id) do
      nil ->
        {:error, Error.execution("Prospect not found"), frame}

      prospect ->
        case GoToMarket.update_prospect(prospect, attributes) do
          {:ok, updated_prospect} ->
            response =
              Response.tool()
              |> Response.structured(%{
                prospect: GoToMarketProspectSerializer.serialize(updated_prospect)
              })

            {:reply, response, frame}

          {:error, changeset} ->
            {:error, Error.execution("Could not update prospect: #{format_errors(changeset)}"),
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
