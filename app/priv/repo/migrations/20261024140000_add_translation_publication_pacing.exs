defmodule Glossia.Repo.Migrations.AddTranslationPublicationPacing do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :translation_last_pushed_at, :utc_datetime_usec
    end
  end
end
