defmodule Glossia.ProjectSetup do
  @moduledoc """
  Enqueues automated project setup using the configured workspace adapter.

  Community uses a local workspace for trusted repositories. Enterprise
  supplies a Kubernetes-backed adapter without changing this queueing flow.
  """

  alias Glossia.Projects.SetupWorker

  def start(project) do
    case %{project_id: project.id}
         |> SetupWorker.new()
         |> Oban.insert() do
      {:ok, _job} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def retry(project_id) do
    case SetupWorker.retry_now(project_id) do
      {:ok, _job} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
