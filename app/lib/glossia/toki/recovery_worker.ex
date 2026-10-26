defmodule Glossia.Toki.RecoveryWorker do
  @moduledoc "Marks interrupted inference failed without generating a duplicate reply."
  use Oban.Worker,
    queue: :default,
    max_attempts: 1,
    unique: [period: 50, states: [:available, :scheduled, :executing, :retryable]]

  @impl Oban.Worker
  def perform(%Oban.Job{}), do: Glossia.Toki.expire_interrupted_replies()
end
