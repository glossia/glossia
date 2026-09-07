defmodule Glossia.Repo.Migrations.CreateSandboxes do
  use Ecto.Migration

  def change do
    create table(:sandboxes, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :project_id, references(:projects, type: :binary_id, on_delete: :nilify_all)

      add :status, :string, null: false, default: "pending"
      add :purpose, :string, null: false, default: "manual"
      add :backend, :string, null: false, default: "flame"
      add :backend_ref, :string
      add :labels, :map, null: false, default: %{}
      add :error, :text
      add :ready_at, :utc_datetime_usec
      add :deadline_at, :utc_datetime_usec
      add :terminated_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:sandboxes, [:account_id])
    create index(:sandboxes, [:project_id])
    create index(:sandboxes, [:account_id, :status])
    create index(:sandboxes, [:deadline_at])

    create table(:sandbox_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :sandbox_id, references(:sandboxes, type: :binary_id, on_delete: :delete_all),
        null: false

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :project_id, references(:projects, type: :binary_id, on_delete: :nilify_all)

      add :status, :string, null: false, default: "open"
      add :opened_at, :utc_datetime_usec, null: false
      add :closed_at, :utc_datetime_usec
      add :close_reason, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:sandbox_sessions, [:sandbox_id])
    create index(:sandbox_sessions, [:account_id])
    create index(:sandbox_sessions, [:status])
  end
end
