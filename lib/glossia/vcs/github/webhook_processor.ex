defmodule Glossia.VCS.Github.WebhookProcessor do
  require Logger

  @doc """
  It processes a webhook sent by GitHub.
  """
  @spec process_webhook(event :: String.t(), payload :: map()) :: nil
  def process_webhook(event, payload) do
    Logger.debug("Processing GitHub webhook: #{event}")

    case event do
      "push" ->
        process_push_webhook(payload)

      _ ->
        nil
    end
  end

  defp process_push_webhook(payload) do
    Logger.debug("Processing the push event")

    with repository_id <- payload |> get_in(["repository", "full_name"]),
         {:project, %Glossia.Projects.Project{} = project} <-
           {:project, Glossia.Projects.find_project_by_repository(repository_id, :github)} do
    else
      {:project, nil} ->
        # Non-existing project
        nil
    end
  end
end
