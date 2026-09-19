defmodule Babel.MCP.CreateGoToMarketProspectTool do
  @moduledoc "Create a public-source prospect record. This tool creates only research and a draft, never sends email."

  use Hermes.Server.Component, type: :tool

  alias Babel.GoToMarket
  alias Babel.GoToMarket.Prospect
  alias Babel.MCP.Authorization
  alias Babel.MCP.GoToMarketProspectSerializer
  alias Hermes.MCP.Error
  alias Hermes.Server.Response

  @statuses Prospect.statuses()

  schema do
    field :company, :string, required: true, description: "Company name."
    field :website_url, :string, required: true, description: "Company secure website address."

    field :translation_tool, :string,
      description: "Known translation tool, if publicly evidenced."

    field :source_title, :string,
      required: true,
      description: "Title of the public research source."

    field :source_url, :string,
      required: true,
      description: "Secure web address for the public research source."

    field :evidence, :string,
      required: true,
      description: "Observed localization or workflow signal."

    field :contact_name, :string, description: "Publicly named contact, if current and relevant."
    field :contact_role, :string, description: "The contact's publicly stated role."

    field :contact_profile_url, :string,
      description: "Secure web address for the public contact profile."

    field :status, :string,
      enum: @statuses,
      description: "Research stage. Defaults to researching."

    field :outreach_angle, :string,
      required: true,
      description: "Specific, low-pressure reason to start a conversation."

    field :intro_email_draft, :string,
      description: "Reviewable email draft. It is never sent by this tool."

    field :next_step, :string,
      required: true,
      description: "Concrete verification or review step before outreach."

    field :organization_id, :integer, description: "Optional organization identifier."
  end

  @impl true
  def execute(params, frame) do
    case Authorization.authorize_write(frame) do
      :ok ->
        case GoToMarket.create_prospect(params) do
          {:ok, prospect} ->
            response =
              Response.tool()
              |> Response.structured(%{
                prospect: GoToMarketProspectSerializer.serialize(prospect)
              })

            {:reply, response, frame}

          {:error, changeset} ->
            {:error, Error.execution("Could not create prospect: #{format_errors(changeset)}"),
             frame}
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
