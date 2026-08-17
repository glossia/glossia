defmodule Glossia.Quality.SessionEvent do
  use Glossia.Schema
  import Ecto.Changeset

  @kinds ~w(
    session_started
    navigation_started
    page_captured
    analysis_started
    finding_recorded
    session_completed
    session_failed
    session_cancelled
  )

  schema "quality_session_events" do
    field :kind, :string
    field :label, :string
    field :detail, :string
    field :metadata, :map, default: %{}

    belongs_to :run, Glossia.Quality.Run
    belongs_to :page, Glossia.Quality.Page
    belongs_to :finding, Glossia.Quality.Finding

    timestamps(updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:run_id, :page_id, :finding_id, :kind, :label, :detail, :metadata])
    |> validate_required([:run_id, :kind, :label, :metadata])
    |> validate_inclusion(:kind, @kinds)
  end
end
