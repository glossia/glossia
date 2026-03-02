defmodule Glossia.Kits.KitTerm do
  use Glossia.Schema
  import Ecto.Changeset

  schema "kit_terms" do
    field :source_term, :string
    field :definition, :string
    field :tags, {:array, :string}, default: []

    belongs_to :kit, Glossia.Kits.Kit

    has_many :translations, Glossia.Kits.KitTermTranslation

    timestamps()
  end

  def changeset(term, attrs) do
    term
    |> cast(attrs, [:source_term, :definition, :tags])
    |> validate_required([:source_term])
    |> validate_length(:source_term, min: 1, max: 255)
    |> unique_constraint([:kit_id, :source_term])
  end
end
