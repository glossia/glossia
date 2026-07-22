defmodule Glossia.Repo.Migrations.AddSetupPullRequestFieldsToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :setup_pull_request_number, :bigint
      add :setup_pull_request_url, :string
      add :setup_pull_request_state, :string
      add :setup_pull_request_merged_at, :utc_datetime_usec
    end

    create constraint(:projects, :setup_pull_request_state_must_be_valid,
             check:
               "setup_pull_request_state IS NULL OR setup_pull_request_state IN ('open', 'merged', 'closed')"
           )

    create index(:projects, [:github_repo_id, :setup_pull_request_number],
             where: "setup_pull_request_number IS NOT NULL"
           )
  end
end
