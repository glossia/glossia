defmodule Glossia.VCS.Github.WebhookProcessor do
  require Logger

  @doc """
  It processes a webhook sent by GitHub.
  """
  @spec process_webhook(event :: String.t(), payload :: map()) :: nil
  def process_webhook(event, payload) do
    Logger.info("Processing GitHub webhook: #{event}")

    case event do
      "push" ->
        process_push_webhook(payload)

      _ ->
        nil
    end
  end

  defp process_push_webhook(payload) do
    Logger.info("Processing the push event")

    with repository_id <- payload |> get_in(["repository", "full_name"]),
         installation_id <- payload |> get_in(["installation", "id"]),
         commit_sha <- payload |> get_in(["after"]) do
      Glossia.Translations.translate(commit_sha, repository_id, installation_id, :github)
    end
  end
end
