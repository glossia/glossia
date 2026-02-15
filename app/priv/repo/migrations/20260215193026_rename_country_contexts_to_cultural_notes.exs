defmodule Glossia.Repo.Migrations.RenameCountryContextsToCulturalNotes do
  use Ecto.Migration

  def change do
    rename table(:voices), :country_contexts, to: :cultural_notes
  end
end
