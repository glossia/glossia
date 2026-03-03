defmodule Glossia.ContentSource do
  @moduledoc """
  Behaviour for fetching content from a project's source repository.

  Each project has a `content_source` field that determines which adapter
  handles its content operations. Adapters implement the callbacks defined
  here. Current adapters:

  - `Glossia.ContentSource.Github` -- reads from GitHub via the REST API
  - `Glossia.ContentSource.LocalGit` -- reads from a local git repo on disk
  """

  @type commit :: %{
          sha: String.t(),
          short_sha: String.t(),
          message: String.t(),
          author_name: String.t(),
          author_avatar_url: String.t() | nil,
          date: DateTime.t() | nil,
          url: String.t() | nil
        }

  @callback list_commits(project :: Glossia.Accounts.Project.t(), opts :: keyword()) ::
              {:ok, list(commit())} | {:error, term()}

  @adapters %{
    "github" => Glossia.ContentSource.Github,
    "local_git" => Glossia.ContentSource.LocalGit
  }

  @doc """
  Lists commits for a project, dispatching to the adapter matching
  the project's `content_source` field.
  """
  @spec list_commits(Glossia.Accounts.Project.t(), keyword()) ::
          {:ok, list(commit())} | {:error, term()}
  def list_commits(project, opts \\ []) do
    case Map.get(@adapters, project.content_source) do
      nil -> {:error, {:unknown_content_source, project.content_source}}
      adapter -> adapter.list_commits(project, opts)
    end
  end
end
