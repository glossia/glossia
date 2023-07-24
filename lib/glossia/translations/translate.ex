defmodule Glossia.Translations.Translate do
  @moduledoc """
  A translate build represents a translation job that's being run in a virtualized environment.
  Locally we use Docker when present, and in production we use Google Cloud Build.
  """

  # Modules
  require Logger
  use Oban.Worker, queue: :translations

  # Impl: Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{
        args:
          %{
            "commit_sha" => commit_sha,
            "repository_id" => repository_id,
            "installation_id" => installation_id,
            "vcs" => vcs
          } = args
      }) do
    Logger.info("Creating state for repository #{repository_id} and commit #{commit_sha}")

    {200, _, _} =
      installation_id
      |> Glossia.VCS.Github.create_commit_status(repository_id, commit_sha, %{
        state: "pending",
        target_url: "https://glossia.ai",
        context: "Glossia / Translating",
        description: "Translating"
      })

    Glossia.Vm.run_builder()
  end

  defp update_state(client, commit_sha, repository_id) do
    client
    |> Glossia.VCS.Github.create_commit_status(repository_id, commit_sha, %{
      state: "pending",
      target_url: "https://glossia.ai",
      context: "Glossia / Translating",
      description: "Translating"
    })
  end

  defp get_client(installation_id) do
    installation_id |> Glossia.VCS.Github.get_client_for_installation()
  end
end
