defmodule Glossia.Repo.Migrations.AddGithubFieldsToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :github_installation_id,
          references(:github_installations, type: :binary_id, on_delete: :nilify_all)

      add :github_repo_id, :bigint
      add :github_repo_full_name, :string
      add :github_repo_default_branch, :string
      add :setup_status, :string
      add :setup_error, :text
    end

    create index(:projects, [:github_installation_id])
    create unique_index(:projects, [:github_repo_id], where: "github_repo_id IS NOT NULL")
  end
end
