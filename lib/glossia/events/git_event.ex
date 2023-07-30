defmodule Glossia.Events.GitEvent do
  @moduledoc """
  This module represents a Git event received for a particular project.
  """

  # Types
  @type t :: %__MODULE__{
          commit_sha: String.t(),
          vcs_id: String.t() | nil,
          vcs_platform: Glossia.VersionControl.Platform.t(),
          vm_id: String.t() | nil,
          status: status(),
          project: Glossia.Projects.Project.t() | nil
        }

  @type event :: :push
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

  schema "git_events" do
    field :commit_sha, :string
    field :vcs_id, :string
    field :vcs_platform, Ecto.Enum, values: [{:github, 1}]
    field :vm_id, :string
    field :vm_logs_url, :string
    field :event, Ecto.Enum, values: [{:push, 1}]

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

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :commit_sha,
      :vcs_id,
      :vcs_platform,
      :project_id,
      :status,
      :vm_id,
      :vm_logs_url,
      :event
    ])
    |> validate_required([
      :commit_sha,
      :vcs_id,
      :vcs_platform,
      :project_id,
      :status,
      :event
    ])
    |> validate_inclusion(:vcs_platform, [:github])
    |> validate_inclusion(:event, [:push])
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
    |> unique_constraint([:commit_sha, :event, :vcs_id, :vcs_platform])
    |> assoc_constraint(:project)
  end
end
