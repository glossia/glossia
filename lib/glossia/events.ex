defmodule Glossia.Events do
  use Boundary, deps: [Glossia.VersionControl, Glossia.Repo, Glossia.Builds], exports: [GitEvent]

  # Modules
  alias Glossia.Events.GitEventWorker
  require Logger

  @doc """
  It proces
  """
  @spec process_git_event(%{
          access_token: String.t(),
          git_access_token: String.t(),
          project_id: number(),
          event: atom(),
          default_branch: String.t(),
          ref: String.t(),
          commit_sha: String.t(),
          vcs_id: String.t(),
          vcs_platform: atom()
        }) ::
          {:ok, nil} | {:error, any()}
  def process_git_event(attrs) do
    attrs
    |> GitEventWorker.new()
    |> Oban.insert()
    |> case do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
