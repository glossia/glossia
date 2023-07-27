defmodule Glossia.Builds do
  use Boundary, deps: [Glossia.VersionControl, Glossia.Repo], exports: [Build]

  # Modules
  alias Glossia.Builds.Worker
  require Logger

  @doc """
  It triggers a build in a virtualized environment.
  """
  @spec trigger_git_event_build(%{
          project_id: number(),
          event: atom(),
          git_commit_sha: String.t(),
          git_repository_id: String.t(),
          vcs_platform: atom()
        }) ::
          {:ok, nil} | {:error, any()}
  def trigger_git_event_build(attrs) do
    attrs
    |> Worker.new()
    |> Oban.insert()
    |> case do
      {:ok, _} -> {:ok, nil}
      {:error, error} -> {:error, error}
    end
  end
end
