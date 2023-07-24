defmodule Glossia.Translations.Translation do
  @moduledoc """
  This module represents the translations table. A translation
  is tied to a repository and commit sha.
  """

  # Types
  @type t :: %__MODULE__{
          commit_sha: String.t(),
          repository_id: String.t() | nil,
          vcs: Glossia.VCS.t(),
          project: Glossia.Projects.Project.t() | nil
        }

  # Modules
  use Ecto.Schema
  import Ecto.Changeset

  # Schema

  schema "translations" do
    field :commit_sha, :string
    field :repository_id, :string
    field :vcs, Ecto.Enum, values: [{:github, 1}]
    belongs_to :project, Glossia.Projects.Project

    timestamps()
  end

  # Changesets

  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:commit_sha, :repository_id, :vcs, :project_id])
    |> validate_required([:commit_sha, :repository_id, :vcs, :project_id])
    |> validate_inclusion(:vcs, [:github])
    |> unique_constraint([:commit_sha, :repository_id, :vcs])
    |> assoc_constraint(:project)
  end
end
