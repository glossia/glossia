defmodule Glossia.Builds.Build do
  @moduledoc false

  # Types
  @type t :: %__MODULE__{
          version: String.t(),
          vm_id: String.t() | nil,
          status: status(),
          project: Glossia.Projects.Project.t() | nil,
          metadata: map()
        }

  @type event :: :new_version
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
  use Glossia.DatabaseSchema
  import Ecto.Changeset

  # Schema

  schema "builds" do
    field :version, :string
    field :content_platform, Ecto.Enum, values: [{:github, 1}]
    field :vm_id, :string
    field :vm_logs_url, :string
    field :markdown_error_message, :string
    field :type, Ecto.Enum, values: [{:new_version, 1}]
    field :metadata, :map

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
      :version,
      :content_platform,
      :project_id,
      :status,
      :vm_id,
      :vm_logs_url,
      :type,
      :markdown_error_message
    ])
    |> validate_required([
      :version,
      :content_platform,
      :project_id,
      :status,
      :type
    ])
    |> validate_inclusion(:content_platform, [:github])
    |> validate_inclusion(:type, [:new_version])
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
    |> unique_constraint([:version, :type],
      name: "builds_version_type_index"
    )
    |> assoc_constraint(:project)
  end
end
