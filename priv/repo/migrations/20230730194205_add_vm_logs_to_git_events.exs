defmodule Glossia.Repo.Migrations.AddVmLogsToGitEvents do
  use Ecto.Migration

  def change do
    alter table(:git_events) do
      add(:vm_logs_url, :string, null: true)
    end
  end
end
