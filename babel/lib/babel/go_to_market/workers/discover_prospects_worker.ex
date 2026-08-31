defmodule Babel.GoToMarket.Workers.DiscoverProspectsWorker do
  @moduledoc false

  use Oban.Worker,
    queue: :prospect_discovery,
    max_attempts: 3,
    unique: [period: 86_400]

  alias Babel.GoToMarket

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    case GoToMarket.discover_new_prospects() do
      {:ok, _summary} -> :ok
      {:error, :search_not_configured} -> {:cancel, :search_not_configured}
      {:error, reason} -> {:error, reason}
    end
  end
end
