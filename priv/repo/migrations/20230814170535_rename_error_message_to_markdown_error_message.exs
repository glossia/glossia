defmodule Glossia.Repo.Migrations.RenameErrorMessageToMarkdownErrorMessage do
  use Ecto.Migration

  def change do
    rename table(:git_events), :error_message, to: :markdown_error_message
  end
end
