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
            "vcs" => vcs
          } = args
      }) do
    Logger.info("Creating state for repository #{repository_id} and commit #{commit_sha}")
    vcs = String.to_atom(vcs)

    Glossia.VCS.create_commit_status(commit_sha, repository_id, vcs, %{
      state: "pending",
      target_url: "https://glossia.ai",
      context: "Glossia / Translating",
      description: "Translating"
    })

    Glossia.Vm.run_builder()

    Glossia.VCS.create_commit_status(commit_sha, repository_id, vcs, %{
      state: "success",
      target_url: "https://glossia.ai",
      context: "Glossia / Translating",
      description: "Translating"
    })
  end
end
