defmodule Glossia.Events do
  use Boundary, deps: [Glossia.VersionControl, Glossia.Repo, Glossia.Builds], exports: [GitEvent]

  # Modules
  alias Glossia.Events.Worker
  require Logger

  @doc """
  It proces
  """
  @spec process_git_event(%{
          project_id: number(),
          event: atom(),
          commit_sha: String.t(),
          vcs_id: String.t(),
          vcs_platform: atom()
        }) ::
          {:ok, nil} | {:error, any()}
  def process_git_event(attrs) do
    attrs
    |> Worker.new()
    |> Oban.insert()
    |> case do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
