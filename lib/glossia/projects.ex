defmodule Glossia.Projects do
  use Boundary, deps: [Glossia.Repo, Glossia.Events, Glossia.VersionControl], exports: [Project]

  @moduledoc """
  The projects context
  """

  alias Glossia.Repo
  alias Glossia.Projects.{Project, ProjectToken}

  @doc """
  Given a git event, it processes it.
  """
  @type process_git_event_opts_t :: [event: String.t(), default_branch: String.t(), commit_sha: String.t(), ref: String.t()]
  @spec process_git_event(project :: Project.t(), opts :: process_git_event_opts_t) :: :ok

  def process_git_event(project, opts) do
    event = opts |> Keyword.fetch!(:event)
    default_branch = opts |> Keyword.fetch!(:default_branch)
    commit_sha = opts |> Keyword.fetch!(:commit_sha)
    ref = opts |> Keyword.get(:ref)

    :ok = %{ event: event, vcs_id: project.vcs_id, vcs_platform: project.vcs_platform, project_id: project.id, commit_sha: commit_sha, default_branch: default_branch, ref: ref}
      |> Map.put(:access_token, generate_token_for_project(project))
      |> Map.put(:git_access_token, Glossia.VersionControl.generate_token_for_cloning(%{ vcs_id: project.vcs_id, vcs_platform: project.vcs_platform }))
      |> Glossia.Events.process_git_event()


    # TODO: Ignore events that are coming from a branch other than the default.
    # ["refs", "heads" | tail] = Map.fetch!(attrs, :ref) |> String.split("/")
    # branch = tail |> Enum.join("/")
    :ok
  end

  @doc """
  Creates a new project with the given attributes.
  """
  @spec create_project(attrs :: Project.changeset_attrs()) ::
          {:ok, Project.t()} | {:error, Ecto.Changeset.t()}
  def create_project(attrs) do
    %Project{} |> Project.changeset(attrs) |> Repo.insert()
  end

  @doc """
  It finds a repository given the id and the vcs.
  """
  @spec find_project_by_repository(%{
          vcs_id: String.t(),
          vcs_platform: Project.vcs()
        }) ::
          Project.t() | nil
  def find_project_by_repository(attrs) do
    Project.find_project_by_repository_query(attrs) |> Repo.one()
  end

  @doc """
  It generates a token for the given project to authenticate requests coming from builds.
  """
  @spec generate_token_for_project(Project.t()) :: String.t()
  def generate_token_for_project(project) do
    {:ok, token, _claims} = ProjectToken.generate_token_for_project_with_id(project.id)
    token
  end

  @doc """
  It generates a token for the given project id to authenticate requests coming from builds.
  """
  @spec generate_token_for_project_with_id(String.t()) :: String.t()
  def generate_token_for_project_with_id(project_id) do
    {:ok, token, _claims} = ProjectToken.generate_token_for_project_with_id(project_id)
    token
  end

  @doc """
  It gets the project from the given token. If the project does not exist, it returns nil.
  """
  @spec get_project_from_token(String.t()) :: Project.t() | nil
  def get_project_from_token(token) do
    case ProjectToken.get_project_id_from_token(token) do
      {:ok, project_id} ->
        Repo.get(Project, project_id)

      {:error, _} ->
        nil
    end
  end
end
