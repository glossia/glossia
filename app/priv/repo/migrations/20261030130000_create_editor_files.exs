defmodule Glossia.Repo.Migrations.CreateEditorFiles do
  use Ecto.Migration

  def change do
    create table(:editor_files, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :project_id, references(:projects, type: :uuid, on_delete: :delete_all), null: false
      add :path, :text, null: false
      add :source_path, :text, null: false
      add :locale, :text, null: false
      add :format, :text, null: false
      add :content, :text, null: false
      add :blob_sha, :text
      add :mode, :text, null: false, default: "100644"
      add :draft_content, :text
      add :branch, :text
      add :pull_request_url, :text
      add :pull_request_number, :integer
      add :conflict, :boolean, null: false, default: false
      add :active, :boolean, null: false, default: true
      add :lock_version, :integer, null: false, default: 1
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:editor_files, [:project_id, :path])
  end
end
