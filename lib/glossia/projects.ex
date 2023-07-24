defmodule Glossia.Projects do
  use Boundary, deps: [Glossia.Repo], exports: [Project]

  @moduledoc """
  The projects context
  """

  alias Glossia.Repo
  alias Glossia.Projects.Project

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
  @spec find_project_by_repository(
          repository_id :: String.t(),
          vcs :: Project.vcs()
        ) ::
          Project.t() | nil
  def find_project_by_repository(repository_id, vcs) do
    Project.find_by_repository_query(repository_id, vcs) |> Repo.one()
  end

  def get_project_configuration() do
  end
end
