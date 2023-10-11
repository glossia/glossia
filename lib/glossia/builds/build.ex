defmodule Glossia.Builds.Build do
  # Types
  @type t :: %__MODULE__{
          version: String.t(),
          content_source_id: String.t() | nil,
          content_source_platform:
            Glossia.ContentSources.ContentSource.content_source_t(),
          vm_id: String.t() | nil,
          status: status(),
          project: Glossia.Projects.Models.Project.t() | nil,
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

  # Modules
  use Glossia.DatabaseSchema
  import Ecto.Changeset

  # Schema

  schema "builds" do
    field :version, :string
    field :content_source_id, :string
    field :content_source_platform, Ecto.Enum, values: [{:github, 1}]
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

    belongs_to :project, Glossia.Projects.Models.Project

    timestamps()
  end

  # Changesets

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :version,
      :content_source_id,
      :content_source_platform,
      :project_id,
      :status,
      :vm_id,
      :vm_logs_url,
      :type,
      :markdown_error_message
    ])
    |> validate_required([
      :version,
      :content_source_id,
      :content_source_platform,
      :project_id,
      :status,
      :type
    ])
    |> validate_inclusion(:content_source_platform, [:github])
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
    |> unique_constraint([:version, :type, :content_source_id, :content_source_platform],
      name: "builds_version_type_content_source_id_content_source_platform_i"
    )
    |> assoc_constraint(:project)
  end
end
