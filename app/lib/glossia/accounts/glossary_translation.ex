defmodule Glossia.Accounts.GlossaryTranslation do
  use Glossia.Schema
  import Ecto.Changeset
  import Glossia.Validations

  schema "glossary_translations" do
    field :locale, :string
    field :translation, :string

    belongs_to :glossary_entry, Glossia.Accounts.GlossaryEntry

    timestamps(updated_at: false)
  end

  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:locale, :translation])
    |> validate_required([:locale, :translation])
    |> validate_locale(:locale)
    |> unique_constraint([:glossary_entry_id, :locale])
  end
end
