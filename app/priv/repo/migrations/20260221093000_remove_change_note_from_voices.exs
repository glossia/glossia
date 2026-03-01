defmodule Glossia.Repo.Migrations.RemoveChangeNoteFromVoices do
  use Ecto.Migration

  def change do
    alter table(:voices) do
      remove :change_note, :string
    end
  end
end
