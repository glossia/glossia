defmodule Glossia.Quality.Page do
  use Glossia.Schema
  import Ecto.Changeset

  schema "quality_pages" do
    field :locale, :string
    field :logical_path, :string
    field :requested_url, :string
    field :final_url, :string
    field :title, :string
    field :document_locale, :string
    field :visible_text, :string, default: ""
    field :alternate_links, :map, default: %{}
    field :content_hash, :string
    field :screenshot_path, :string
    field :load_error, :string

    belongs_to :run, Glossia.Quality.Run
    belongs_to :project, Glossia.Accounts.Project
    has_many :session_events, Glossia.Quality.SessionEvent

    timestamps(updated_at: false)
  end

  def changeset(page, attrs) do
    page
    |> cast(attrs, [
      :run_id,
      :project_id,
      :locale,
      :logical_path,
      :requested_url,
      :final_url,
      :title,
      :document_locale,
      :visible_text,
      :alternate_links,
      :content_hash,
      :screenshot_path,
      :load_error
    ])
    |> validate_required([:run_id, :project_id, :locale, :logical_path, :requested_url])
    |> validate_length(:locale, max: 64, count: :bytes)
    |> validate_length(:logical_path, max: 255, count: :bytes)
    |> validate_length(:document_locale, max: 64, count: :bytes)
    |> unique_constraint([:run_id, :locale, :logical_path])
  end
end
