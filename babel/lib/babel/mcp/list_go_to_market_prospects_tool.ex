defmodule Babel.MCP.ListGoToMarketProspectsTool do
  @moduledoc "List public-source go-to-market prospect research and reviewable outreach drafts."

  use Hermes.Server.Component, type: :tool, annotations: %{"readOnlyHint" => true}

  alias Babel.GoToMarket
  alias Babel.GoToMarket.Prospect
  alias Babel.MCP.Authorization
  alias Babel.MCP.GoToMarketProspectSerializer
  alias Hermes.Server.Response

  @statuses Prospect.statuses()

  schema do
    field :status, :string,
      enum: @statuses,
      description: "Optional research stage to filter by."
  end

  @impl true
  def execute(params, frame) do
    case Authorization.authorize(frame) do
      :ok ->
        options = if status = params[:status], do: [status: status], else: []

        response =
          Response.tool()
          |> Response.structured(%{
            prospects:
              options
              |> GoToMarket.list_prospects()
              |> Enum.map(&GoToMarketProspectSerializer.serialize/1),
            summary: GoToMarket.prospect_summary()
          })

        {:reply, response, frame}

      {:error, error} ->
        {:error, error, frame}
    end
  end
end
