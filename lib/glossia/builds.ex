defmodule Glossia.Builds do
  use Boundary, deps: [Glossia.VCS, Glossia.Repo], exports: [Build]

  # Modules
  alias Glossia.Builds.Worker
  require Logger

  @doc """
  It triggers a build in a virtualized environment.
  """
  @spec trigger_build(%{
          project_id: number(),
          event: atom(),
          commit_sha: String.t(),
          repository_id: String.t(),
          vcs: atom()
        }) ::
          {:ok, nil} | {:error, any()}
  def trigger_build(attrs) do
    attrs
    |> Worker.new()
    |> Oban.insert()
    |> case do
      {:ok, _} -> {:ok, nil}
      {:error, error} -> {:error, error}
    end
  end
end
