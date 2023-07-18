defmodule Glossia.Projects do
  @moduledoc """
  The projects context
  """

  alias Glossia.Repo
  alias Glossia.Projects.Project

  def create_project(opts) do
    Repo.insert(Project.create_changeset(opts))
  end
end
