defmodule Glossia.Quality.Occurrence do
  use Glossia.Schema
  import Ecto.Changeset

  schema "quality_occurrences" do
    field :evidence, :map, default: %{}
    field :screenshot_path, :string

    belongs_to :finding, Glossia.Quality.Finding
    belongs_to :run, Glossia.Quality.Run
    belongs_to :page, Glossia.Quality.Page

    timestamps(updated_at: false)
  end

  def changeset(occurrence, attrs) do
    occurrence
    |> cast(attrs, [:finding_id, :run_id, :page_id, :evidence, :screenshot_path])
    |> validate_required([:finding_id, :run_id, :evidence])
    |> unique_constraint([:finding_id, :run_id, :page_id])
  end
end
