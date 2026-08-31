defmodule Babel.MCP.DiscoverGoToMarketProspectsTool do
  @moduledoc "Queue a public-source organization discovery run. It creates researching organizations and never sends outreach."

  use Hermes.Server.Component, type: :tool

  alias Babel.GoToMarket.Workers.DiscoverProspectsWorker
  alias Babel.MCP.Authorization
  alias Hermes.MCP.Error
  alias Hermes.Server.Response

  schema do
  end

  @impl true
  def execute(_params, frame) do
    case Authorization.authorize_write(frame) do
      :ok ->
        case DiscoverProspectsWorker.new(%{}) |> Oban.insert() do
          {:ok, job} ->
            response =
              Response.tool()
              |> Response.structured(%{job_id: job.id, status: job.state})

            {:reply, response, frame}

          {:error, reason} ->
            {:error, Error.execution("Could not queue discovery: #{inspect(reason)}"), frame}
        end

      {:error, error} ->
        {:error, error, frame}
    end
  end
end
