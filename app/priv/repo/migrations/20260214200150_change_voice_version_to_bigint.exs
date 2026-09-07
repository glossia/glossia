defmodule Glossia.Repo.Migrations.ChangeVoiceVersionToBigint do
  use Ecto.Migration

  def change do
    alter table(:voices) do
      modify :version, :bigint, from: :integer
    end
  end
end
