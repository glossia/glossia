defmodule Glossia.Quality.RunRecoveryWorker do
  @moduledoc "Ends abandoned browser reviews so they cannot block later runs."

  use Oban.Worker,
    queue: :default,
    max_attempts: 1,
    unique: [period: 240, states: [:available, :scheduled, :executing, :retryable]]

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Glossia.Quality.expire_stale_runs()
    :ok
  end
end
