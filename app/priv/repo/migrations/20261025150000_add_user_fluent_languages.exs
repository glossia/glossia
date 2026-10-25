defmodule Glossia.Repo.Migrations.AddUserFluentLanguages do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :fluent_languages, {:array, :string}, default: [], null: false
    end
  end
end
