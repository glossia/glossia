defmodule GlossiaEnterprise.ProjectSetup do
  @moduledoc """
  Enterprise `Glossia.ProjectSetup` implementation.

  Wires the automated project-onboarding flow that used to live in
  `Glossia.Projects.Setup` into the seam glossia exposes. Everything the
  flow needs — the harness orchestrator, the sandbox schemas, and the
  Kata-scheduled `GlossiaEnterprise.Sandbox.KataAdapter` — is inside this
  repository. `start/1` enqueues the same Oban worker the OSS build used
  to enqueue; `retry/1` calls `retry_now/1` for a rescheduled run.
  """

  @behaviour Glossia.ProjectSetup

  alias GlossiaEnterprise.Projects.SetupWorker

  @impl true
  def start(project) do
    case %{project_id: project.id}
         |> SetupWorker.new()
         |> Oban.insert() do
      {:ok, _job} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def retry(project_id) do
    case SetupWorker.retry_now(project_id) do
      {:ok, _job} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
