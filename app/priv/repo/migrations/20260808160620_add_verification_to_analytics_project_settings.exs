defmodule Glossia.Repo.Migrations.AddVerificationToAnalyticsProjectSettings do
  use Ecto.Migration

  def change do
    alter table(:analytics_project_settings) do
      add :verification_token, :string, size: 64
      add :verified_at, :utc_datetime_usec
    end

    # Existing rows predate verification. Give each one a token and mark it
    # verified so the dogfooded `glossia-web.js` snippet keeps collecting
    # without forcing every operator through the DNS dance. The dashboard
    # exposes a "Re-verify" action for projects that want to re-run the check.
    execute("""
    UPDATE analytics_project_settings
       SET verification_token = md5(random()::text) || md5(random()::text),
           verified_at = NOW()
     WHERE verification_token IS NULL
    """)

    alter table(:analytics_project_settings) do
      modify :verification_token, :string, size: 64, null: false
    end

    create index(:analytics_project_settings, [:verified_at])
  end
end
