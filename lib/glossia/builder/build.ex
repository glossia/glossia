defmodule Glossia.Builder.Build do
  @moduledoc """
  This module represents the builds table.
  """

  # Types
  @type t :: %__MODULE__{
          commit_sha: String.t(),
          repository_id: String.t() | nil,
          vcs: Glossia.VCS.t(),
          project: Glossia.Projects.Project.t() | nil
        }

  @type event :: :git_push
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

  schema "builds" do
    field :commit_sha, :string
    field :repository_id, :string
    field :vcs, Ecto.Enum, values: [{:github, 1}]
    field :remote_id, :string
    field :event, Ecto.Enum, values: [{:git_push, 1}]

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

  def changeset(build, attrs) do
    build
    |> cast(attrs, [:commit_sha, :repository_id, :vcs, :project_id, :status, :remote_id, :event])
    |> validate_required([:commit_sha, :repository_id, :vcs, :project_id, :status, :event])
    |> validate_inclusion(:vcs, [:github])
    |> validate_inclusion(:event, [:git_push])
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
