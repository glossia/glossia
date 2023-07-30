defmodule Glossia.Projects do
  use Boundary, deps: [Glossia.Repo], exports: [Project]

  @moduledoc """
  The projects context
  """

  alias Glossia.Repo
  alias Glossia.Projects.{Project, ProjectToken}

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
    Project.find_project_by_repository(attrs) |> Repo.one()
  end

  @doc """
  It generates a token for the given project to authenticate requests coming from builds.
  """
  @spec generate_token_for_project(Project.t()) :: String.t()
  def generate_token_for_project(project) do
    {:ok, token, _claims} = ProjectToken.generate_token(project)
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
