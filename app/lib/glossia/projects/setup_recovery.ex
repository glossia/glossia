defmodule Glossia.Projects.SetupRecovery do
  @moduledoc false

  use GenServer

  require Logger

  alias Glossia.{Ingestion, Projects}

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    {:ok, %{}, {:continue, :recover}}
  end

  @impl true
  def handle_continue(:recover, state) do
    recover_active_setups()
    {:noreply, state}
  end

  defp recover_active_setups do
    Projects.list_projects_with_active_setup()
    |> Enum.each(&recover_project/1)
  end

  defp recover_project(project) do
    with {:ok, project} <- Projects.reset_project_setup_for_recovery(project),
         :ok <- record_recovery_event(project),
         {:ok, _job} <-
           %{project_id: project.id}
           |> Glossia.Projects.SetupWorker.new()
           |> Oban.insert() do
      Logger.info("Recovered setup onboarding for project #{project.id}")
    else
      {:error, reason} ->
        Logger.warning(
          "Could not recover setup onboarding for project #{project.id}: #{inspect(reason)}"
        )
    end
  end

  defp record_recovery_event(project) do
    sequence = Ingestion.max_setup_event_sequence(project.id) + 1
    metadata = JSON.encode!(%{"recovered" => true})

    Ingestion.record_setup_event(
      project.id,
      sequence,
      "status",
      "Setup onboarding was recovered after the server restarted. Glossia is restarting it from persisted project state.",
      metadata
    )

    Projects.broadcast_setup_event(project, %{
      sequence: sequence,
      event_type: "status",
      content:
        "Setup onboarding was recovered after the server restarted. Glossia is restarting it from persisted project state.",
      metadata: metadata
    })

    :ok
  end
end
