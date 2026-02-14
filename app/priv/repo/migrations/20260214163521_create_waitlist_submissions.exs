defmodule Glossia.Repo.Migrations.CreateWaitlistSubmissions do
  use Ecto.Migration

  def change do
    create table(:waitlist_submissions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :email, :string, null: false
      add :company, :string
      add :url, :string
      add :description, :text
      add :motivation, :text
      add :target_languages, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:waitlist_submissions, [:user_id])
    create unique_index(:waitlist_submissions, [:email])
  end
end
