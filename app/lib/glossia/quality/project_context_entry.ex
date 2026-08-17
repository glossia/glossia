defmodule Glossia.Quality.ProjectContextEntry do
  use Glossia.Schema
  import Ecto.Changeset

  @kinds ~w(terminology locale_guidance quality_rule)

  schema "project_context_entries" do
    field :kind, :string
    field :locale, :string
    field :source_text, :string
    field :instruction, :string
    field :route_scope, :string

    belongs_to :project_context_version, Glossia.Quality.ProjectContextVersion
    belongs_to :origin_finding, Glossia.Quality.Finding

    timestamps(updated_at: false)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :project_context_version_id,
      :origin_finding_id,
      :kind,
      :locale,
      :source_text,
      :instruction,
      :route_scope
    ])
    |> validate_required([:project_context_version_id, :kind, :locale, :instruction])
    |> validate_inclusion(:kind, @kinds)
    |> validate_format(:locale, ~r/^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$/,
      message: "must be a valid locale like en or pt-BR"
    )
    |> validate_length(:source_text, max: 2_000)
    |> validate_length(:instruction, max: 4_000)
    |> validate_length(:route_scope, max: 500)
    |> validate_terminology_source()
  end

  defp validate_terminology_source(changeset) do
    if get_field(changeset, :kind) == "terminology" do
      validate_required(changeset, [:source_text])
    else
      changeset
    end
  end
end
