defmodule Glossia.Repo.Migrations.AddSetupSandboxIdToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :setup_sandbox_id, :string
    end
  end
end
