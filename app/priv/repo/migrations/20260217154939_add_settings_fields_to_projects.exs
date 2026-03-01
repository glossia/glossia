defmodule Glossia.Repo.Migrations.AddSettingsFieldsToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :description, :text
      add :url, :string
      add :avatar_url, :string
    end
  end
end
