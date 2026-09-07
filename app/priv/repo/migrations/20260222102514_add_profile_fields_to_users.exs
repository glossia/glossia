defmodule Glossia.Repo.Migrations.AddProfileFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :bio, :text
      add :github_url, :string
      add :x_url, :string
      add :linkedin_url, :string
      add :mastodon_url, :string
    end
  end
end
