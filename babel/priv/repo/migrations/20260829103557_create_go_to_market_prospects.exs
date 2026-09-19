defmodule Babel.Repo.Migrations.CreateGoToMarketProspects do
  use Ecto.Migration

  def change do
    create table(:go_to_market_prospects) do
      add :company, :string, null: false
      add :website_url, :string, null: false
      add :translation_tool, :string
      add :source_title, :string, null: false
      add :source_url, :string, null: false
      add :evidence, :text, null: false
      add :contact_name, :string
      add :contact_role, :string
      add :contact_profile_url, :string
      add :status, :string, null: false, default: "researching"
      add :outreach_angle, :text, null: false
      add :intro_email_draft, :text
      add :next_step, :text, null: false
      add :owner, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:go_to_market_prospects, [:company, :source_url])
    create index(:go_to_market_prospects, [:status])
  end
end
