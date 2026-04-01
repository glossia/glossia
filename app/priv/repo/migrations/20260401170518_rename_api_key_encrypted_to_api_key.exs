defmodule Glossia.Repo.Migrations.RenameApiKeyEncryptedToApiKey do
  use Ecto.Migration

  def change do
    rename table(:llm_models), :api_key_encrypted, to: :api_key
  end
end
