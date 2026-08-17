defmodule Glossia.Repo.Migrations.CreateQualityAudits do
  use Ecto.Migration

  def change do
    create table(:quality_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      add :source_locale, :string, null: false
      add :locale_origins, :map, null: false, default: %{}
      add :seed_paths, {:array, :string}, null: false, default: ["/"]
      add :max_pages, :integer, null: false, default: 20

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:quality_profiles, [:project_id])

    create table(:quality_runs, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      add :triggered_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :sandbox_id, references(:sandboxes, type: :binary_id, on_delete: :nilify_all)
      add :status, :string, null: false, default: "pending"
      add :configuration, :map, null: false, default: %{}
      add :pages_count, :integer, null: false, default: 0
      add :findings_count, :integer, null: false, default: 0
      add :error, :text
      add :started_at, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:quality_runs, [:account_id])
    create index(:quality_runs, [:project_id, :inserted_at])
    create index(:quality_runs, [:status])

    create table(:quality_pages, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :run_id, references(:quality_runs, type: :binary_id, on_delete: :delete_all),
        null: false

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      add :locale, :string, null: false
      add :logical_path, :string, null: false
      add :requested_url, :text, null: false
      add :final_url, :text
      add :title, :text
      add :document_locale, :string
      add :visible_text, :text, null: false, default: ""
      add :alternate_links, :map, null: false, default: %{}
      add :content_hash, :string
      add :screenshot_path, :text
      add :load_error, :text

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:quality_pages, [:run_id, :locale, :logical_path])
    create index(:quality_pages, [:project_id])

    create table(:quality_findings, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      add :fingerprint, :string, null: false
      add :check, :string, null: false
      add :category, :string, null: false
      add :severity, :string, null: false
      add :status, :string, null: false, default: "open"
      add :title, :string, null: false
      add :description, :text, null: false
      add :locale, :string
      add :logical_path, :string
      add :source_text, :text
      add :target_text, :text
      add :metadata, :map, null: false, default: %{}
      add :first_seen_at, :utc_datetime_usec, null: false
      add :last_seen_at, :utc_datetime_usec, null: false
      add :resolved_at, :utc_datetime_usec
      add :dismissed_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:quality_findings, [:project_id, :fingerprint])
    create index(:quality_findings, [:project_id, :status])
    create index(:quality_findings, [:project_id, :severity])

    create table(:quality_occurrences, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :finding_id,
          references(:quality_findings, type: :binary_id, on_delete: :delete_all),
          null: false

      add :run_id, references(:quality_runs, type: :binary_id, on_delete: :delete_all),
        null: false

      add :page_id, references(:quality_pages, type: :binary_id, on_delete: :nilify_all)
      add :evidence, :map, null: false, default: %{}
      add :screenshot_path, :text

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:quality_occurrences, [:finding_id, :run_id, :page_id])
    create index(:quality_occurrences, [:run_id])

    create table(:project_context_versions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      add :created_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :version, :bigint, null: false
      add :change_note, :text

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:project_context_versions, [:project_id, :version])
    create index(:project_context_versions, [:project_id])

    create table(:project_context_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :project_context_version_id,
          references(:project_context_versions, type: :binary_id, on_delete: :delete_all),
          null: false

      add :origin_finding_id,
          references(:quality_findings, type: :binary_id, on_delete: :nilify_all)

      add :kind, :string, null: false
      add :locale, :string, null: false
      add :source_text, :text
      add :instruction, :text, null: false
      add :route_scope, :text

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:project_context_entries, [:project_context_version_id])
    create index(:project_context_entries, [:origin_finding_id])
  end
end
