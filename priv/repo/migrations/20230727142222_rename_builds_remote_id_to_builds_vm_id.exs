defmodule Glossia.Repo.Migrations.RenameBuildsRemoteIdToBuildsVmId do
  use Ecto.Migration

  def change do
    rename table("builds"), :remote_id, to: :vm_id
  end
end
