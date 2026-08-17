defmodule Glossia.Quality.Finding do
  use Glossia.Schema
  import Ecto.Changeset

  @statuses ~w(open acknowledged resolved dismissed)
  @severities ~w(info low medium high)

  schema "quality_findings" do
    field :fingerprint, :string
    field :check, :string
    field :category, :string
    field :severity, :string
    field :status, :string, default: "open"
    field :title, :string
    field :description, :string
    field :locale, :string
    field :logical_path, :string
    field :source_text, :string
    field :target_text, :string
    field :metadata, :map, default: %{}
    field :first_seen_at, :utc_datetime_usec
    field :last_seen_at, :utc_datetime_usec
    field :resolved_at, :utc_datetime_usec
    field :dismissed_at, :utc_datetime_usec

    belongs_to :project, Glossia.Accounts.Project
    has_many :occurrences, Glossia.Quality.Occurrence
    has_many :session_events, Glossia.Quality.SessionEvent

    timestamps()
  end

  def changeset(finding, attrs) do
    finding
    |> cast(attrs, [
      :project_id,
      :fingerprint,
      :check,
      :category,
      :severity,
      :status,
      :title,
      :description,
      :locale,
      :logical_path,
      :source_text,
      :target_text,
      :metadata,
      :first_seen_at,
      :last_seen_at,
      :resolved_at,
      :dismissed_at
    ])
    |> validate_required([
      :project_id,
      :fingerprint,
      :check,
      :category,
      :severity,
      :status,
      :title,
      :description,
      :first_seen_at,
      :last_seen_at
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:severity, @severities)
    |> validate_length(:locale, max: 64, count: :bytes)
    |> validate_length(:logical_path, max: 255, count: :bytes)
    |> unique_constraint([:project_id, :fingerprint])
  end
end
