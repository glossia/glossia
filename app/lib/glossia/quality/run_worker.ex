defmodule Glossia.Quality.RunWorker do
  @moduledoc "Durably executes a project localization quality assurance run."

  use Oban.Worker,
    queue: :default,
    max_attempts: 1,
    unique: [keys: [:run_id], states: [:available, :scheduled, :executing, :retryable]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"run_id" => run_id}}) do
    Glossia.Quality.Runner.run(run_id)
  end
end
