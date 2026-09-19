defmodule Babel.MCP.GetGoToMarketProspectTool do
  @moduledoc "Return one public-source prospect record and its draft-only outreach plan."

  use Hermes.Server.Component, type: :tool, annotations: %{"readOnlyHint" => true}

  alias Babel.GoToMarket
  alias Babel.MCP.Authorization
  alias Babel.MCP.GoToMarketProspectSerializer
  alias Hermes.MCP.Error
  alias Hermes.Server.Response

  schema do
    field :id, :integer, required: true, description: "Prospect identifier."
  end

  @impl true
  def execute(%{id: id}, frame) do
    case Authorization.authorize(frame) do
      :ok ->
        case GoToMarket.get_prospect(id) do
          nil ->
            {:error, Error.execution("Prospect not found"), frame}

          prospect ->
            response =
              Response.tool()
              |> Response.structured(%{
                prospect: GoToMarketProspectSerializer.serialize(prospect)
              })

            {:reply, response, frame}
        end

      {:error, error} ->
        {:error, error, frame}
    end
  end
end
