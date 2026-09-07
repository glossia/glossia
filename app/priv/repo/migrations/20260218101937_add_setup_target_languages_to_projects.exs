defmodule Glossia.Repo.Migrations.AddSetupTargetLanguagesToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :setup_target_languages, {:array, :string}, default: []
    end
  end
end
