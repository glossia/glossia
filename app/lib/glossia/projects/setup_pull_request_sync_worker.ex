defmodule Glossia.Projects.SetupPullRequestSyncWorker do
  @moduledoc """
  Reconciles setup pull requests that have not been recorded as merged.

  GitHub webhooks provide the immediate state changes. This periodic pass makes
  the project state recover if a webhook was delayed or missed.
  """

  use Oban.Worker, queue: :default, max_attempts: 1

  require Logger

  alias Glossia.Github
  alias Glossia.Projects

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Projects.list_projects_with_unmerged_setup_pull_requests()
    |> Enum.each(&sync_project/1)

    :ok
  end

  defp sync_project(project) do
    with {:ok, token} <-
           Github.App.installation_token(project.github_installation.github_installation_id),
         {:ok, pull_request} <-
           Github.Client.get_pull_request(
             project.github_repo_full_name,
             project.setup_pull_request_number,
             token
           ),
         {:ok, state, merged_at} <- pull_request_state(pull_request) do
      persist_state(project, state, merged_at)
    else
      {:error, reason} ->
        Logger.warning("Could not reconcile setup pull request",
          project_id: project.id,
          reason: inspect(reason)
        )
    end
  end

  defp persist_state(
         %{setup_pull_request_state: state, setup_pull_request_merged_at: merged_at},
         state,
         merged_at
       ),
       do: :ok

  defp persist_state(project, state, merged_at) do
    case Projects.update_setup_pull_request_state(
           project.github_repo_id,
           project.setup_pull_request_number,
           state,
           merged_at
         ) do
      {:ok, updated_project} ->
        Projects.broadcast_setup_pull_request(updated_project)

      {:error, reason} ->
        Logger.warning("Could not persist reconciled setup pull request",
          project_id: project.id,
          reason: inspect(reason)
        )
    end
  end

  defp pull_request_state(%{"state" => "open"}), do: {:ok, "open", nil}

  defp pull_request_state(%{"state" => "closed", "merged_at" => merged_at})
       when is_binary(merged_at) do
    case DateTime.from_iso8601(merged_at) do
      {:ok, datetime, _offset} -> {:ok, "merged", datetime}
      {:error, reason} -> {:error, {:invalid_merged_at, reason}}
    end
  end

  defp pull_request_state(%{"state" => "closed"}), do: {:ok, "closed", nil}
  defp pull_request_state(response), do: {:error, {:unexpected_pull_request_response, response}}
end
