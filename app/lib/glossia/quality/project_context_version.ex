defmodule Glossia.Quality.ProjectContextVersion do
  use Glossia.Schema
  import Ecto.Changeset

  schema "project_context_versions" do
    field :version, :integer
    field :change_note, :string

    belongs_to :project, Glossia.Accounts.Project
    belongs_to :created_by, Glossia.Accounts.User
    has_many :entries, Glossia.Quality.ProjectContextEntry

    timestamps(updated_at: false)
  end

  def changeset(context, attrs) do
    context
    |> cast(attrs, [:project_id, :created_by_id, :version, :change_note])
    |> validate_required([:project_id, :version])
    |> unique_constraint([:project_id, :version])
  end
end
