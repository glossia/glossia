defmodule Babel.Repo.Migrations.CreateErrorsEvents do
  use Ecto.Migration

  def change do
    create table(:errors_events, primary_key: false) do
      add :event_id, :binary_id, primary_key: true

      add :organization_id,
          references(:organizations, on_delete: :delete_all),
          null: false

      add :issue_id,
          references(:errors_issues, type: :binary_id, on_delete: :delete_all),
          null: false

      add :fingerprint, :string, size: 64, null: false
      add :timestamp, :utc_datetime_usec, null: false
      add :received_at, :utc_datetime_usec, null: false

      add :platform, :string, size: 32
      add :level, :string, size: 16
      add :environment, :string
      add :release, :string
      add :dist, :string
      add :server_name, :string
      add :transaction, :string
      add :logger, :string

      add :exception_type, :string
      add :exception_value, :text
      add :top_frame_function, :string
      add :top_frame_module, :string
      add :top_frame_filename, :string

      add :user_id, :string
      add :user_email, :string
      add :user_ip, :string

      add :request_url, :text
      add :request_method, :string, size: 16

      add :sdk_name, :string
      add :sdk_version, :string

      add :tags, :map, null: false, default: %{}
      add :payload, :text

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:errors_events, [:issue_id, :timestamp])
    create index(:errors_events, [:organization_id, :timestamp])
  end
end
