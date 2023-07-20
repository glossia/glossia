defmodule Glossia.Projects do
  @moduledoc """
  The projects context
  """

  alias Glossia.Repo
  alias Glossia.Projects.Project

  @doc """
  Creates a new project with the given attributes.
  """
  @spec create_project(opts :: Project.changeset_attrs()) ::
          {:ok, Project.t()} | {:error, Ecto.Changeset.t()}
  def create_project(opts) do
    Project.changeset(%Project{}, opts) |> Repo.insert()
  end
end
