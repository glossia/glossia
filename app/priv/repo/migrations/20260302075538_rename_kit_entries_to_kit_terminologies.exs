defmodule Glossia.Repo.Migrations.RenameKitEntriesToKitTerms do
  use Ecto.Migration

  def change do
    rename table(:kit_entries), to: table(:kit_terms)
    rename table(:kit_entry_translations), to: table(:kit_term_translations)

    # Rename foreign key column in kit_term_translations
    rename table(:kit_term_translations), :kit_entry_id, to: :kit_term_id
  end
end
