defmodule Glossia.Repo.Migrations.AddLocaleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Null means "not chosen yet": those users keep following their browser.
      add :locale, :string
    end
  end
end
