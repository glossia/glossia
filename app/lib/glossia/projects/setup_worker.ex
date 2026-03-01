defmodule Glossia.Projects.SetupWorker do
  @moduledoc """
  Oban worker that runs the project setup process.

  Delegates the actual work to `Glossia.Projects.Setup.run/1`, gaining Oban's
  retry semantics, persistence, and lifecycle management for free.
  """

  use Oban.Worker, queue: :default, max_attempts: 3, unique: [keys: [:project_id]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"project_id" => project_id}}) do
    case Glossia.Projects.Setup.run(project_id) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
