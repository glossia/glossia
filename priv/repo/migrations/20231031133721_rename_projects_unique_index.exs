defmodule Glossia.Repo.Migrations.RenameProjectsUniqueIndex do
  use Ecto.Migration

  def up do
    execute "ALTER INDEX projects_account_id_handle_index RENAME TO projects_handle_account_id_index"
  end

  def down do
    execute "ALTER INDEX projects_handle_account_id_index RENAME TO projects_account_id_handle_index"
  end
end
