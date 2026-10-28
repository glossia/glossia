defmodule GlossiaEnterprise.Audit.Migration do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:audit_events, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :account_id, :uuid, null: false
      add :user_id, :uuid
      add :name, :text, null: false
      add :actor_handle, :text
      add :actor_email, :text
      add :resource_type, :text
      add :resource_id, :text
      add :summary, :text
      add :metadata, :map, null: false, default: %{}
      add :occurred_at, :utc_datetime_usec, null: false
    end

    create index(:audit_events, [:account_id, :occurred_at, :id])
    create index(:audit_events, [:account_id, :name, :occurred_at])
  end
end
