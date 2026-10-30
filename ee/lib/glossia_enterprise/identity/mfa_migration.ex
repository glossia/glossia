defmodule GlossiaEnterprise.Identity.MFAMigration do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:organization_security_settings) do
      add :mfa_enforced, :boolean, default: false, null: false
    end
  end
end
