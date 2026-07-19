defmodule Glossia.Projects.SetupWorker do
  @moduledoc """
  Oban worker that runs the project setup process.

  Delegates the actual work to `Glossia.Projects.Setup.run/1`, using Oban for
  persistence and lifecycle management. Failed setup jobs are cancelled so a
  user can inspect the failure before explicitly retrying them.
  """

  use Oban.Worker,
    queue: :default,
    max_attempts: 3,
    unique: [keys: [:project_id], states: [:available, :scheduled, :executing, :retryable]]

  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"project_id" => project_id}}) do
    case Glossia.Projects.Setup.run(project_id) do
      :ok -> :ok
      {:error, reason} -> {:cancel, reason}
    end
  end

  def retry_now(project_id) do
    project_id = to_string(project_id)

    existing_jobs =
      from(job in Oban.Job,
        where: job.worker == ^to_string(__MODULE__),
        where: job.state in ["available", "scheduled", "executing", "retryable"],
        where: fragment("?->>'project_id' = ?", job.args, ^project_id)
      )

    with {:ok, _count} <- Oban.cancel_all_jobs(existing_jobs) do
      %{project_id: project_id}
      |> new()
      |> Oban.insert()
    end
  end
end
