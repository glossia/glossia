defmodule Glossia.Accounts.GlossaryEntry do
  use Glossia.Schema
  import Ecto.Changeset

  schema "glossary_entries" do
    field :term, :string
    field :definition, :string
    field :case_sensitive, :boolean, default: false

    belongs_to :glossary, Glossia.Accounts.Glossary
    has_many :translations, Glossia.Accounts.GlossaryTranslation

    timestamps(updated_at: false)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:term, :definition, :case_sensitive])
    |> validate_required([:term])
    |> unique_constraint([:glossary_id, :term])
  end
end
