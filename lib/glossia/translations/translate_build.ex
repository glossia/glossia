defmodule Glossia.Translations.TranslateBuild do
  @moduledoc """
  A translate build represents a translation job that's being run in a virtualized environment.
  Locally we use Docker when present, and in production we use Google Cloud Build.
  """
  use Oban.Worker, queue: :translations

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"commit_sha" => commit_sha, "repository_id" => repository_id, "vcs" => vcs} = args
      }) do
    Glossia.Vm.Builder.run()
  end
end
