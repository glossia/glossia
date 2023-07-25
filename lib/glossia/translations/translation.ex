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
  @type status ::
          :status_unknown
          | :pending
          | :queued
          | :working
          | :success
          | :failure
          | :internal_error
          | :timeout
          | :cancelled
          | :expired

  # Modules
  use Ecto.Schema
  import Ecto.Changeset

  # Schema

  schema "translations" do
    field :commit_sha, :string
    field :repository_id, :string
    field :vcs, Ecto.Enum, values: [{:github, 1}]
    field :build_id, :string

    field :status, Ecto.Enum,
      values: [
        {:status_unknown, 1},
        {:pending, 2},
        {:queued, 3},
        {:working, 4},
        {:success, 5},
        {:failure, 6},
        {:internal_error, 7},
        {:timeout, 8},
        {:cancelled, 9},
        {:expired, 10}
      ],
      default: :status_unknown

    belongs_to :project, Glossia.Projects.Project

    timestamps()
  end

  # Changesets

  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:commit_sha, :repository_id, :vcs, :project_id, :status, :build_id])
    |> validate_required([:commit_sha, :repository_id, :vcs, :project_id, :status])
    |> validate_inclusion(:vcs, [:github])
    |> validate_inclusion(:status, [
      :status_unknown,
      :pending,
      :queued,
      :working,
      :success,
      :failure,
      :internal_error,
      :timeout,
      :cancelled,
      :expired
    ])
    |> unique_constraint([:commit_sha, :repository_id, :vcs])
    |> assoc_constraint(:project)
  end
end
