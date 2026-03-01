defmodule Glossia.Kits.KitEntryTranslation do
  use Glossia.Schema
  import Ecto.Changeset
  import Glossia.Validations

  schema "kit_entry_translations" do
    field :language, :string
    field :translated_term, :string
    field :usage_note, :string

    belongs_to :kit_entry, Glossia.Kits.KitEntry

    timestamps()
  end

  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:language, :translated_term, :usage_note])
    |> validate_required([:language, :translated_term])
    |> validate_locale(:language)
    |> validate_length(:translated_term, min: 1, max: 500)
    |> unique_constraint([:kit_entry_id, :language])
  end
end
