defmodule Babel.Repo.Migrations.CreateErrorsProjectKeys do
  use Ecto.Migration

  def change do
    execute(
      "CREATE SEQUENCE errors_project_keys_dsn_project_id_seq",
      "DROP SEQUENCE errors_project_keys_dsn_project_id_seq"
    )

    create table(:errors_project_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :organization_id,
          references(:organizations, on_delete: :delete_all),
          null: false

      add :dsn_project_id, :bigint,
        null: false,
        default: fragment("nextval('errors_project_keys_dsn_project_id_seq')")

      add :public_key, :string, size: 32, null: false
      add :secret_key, :string, size: 32
      add :name, :string, null: false, default: "default"
      add :last_used_at, :utc_datetime_usec

      timestamps(type: :utc_datetime)
    end

    create unique_index(:errors_project_keys, [:public_key])
    create unique_index(:errors_project_keys, [:dsn_project_id])
    create index(:errors_project_keys, [:organization_id])

    create unique_index(
             :errors_project_keys,
             [:organization_id, :name],
             name: :errors_project_keys_organization_id_name_index
           )
  end
end
