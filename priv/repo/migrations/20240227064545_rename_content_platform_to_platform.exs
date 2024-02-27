defmodule Glossia.Repo.Migrations.RenameContentPlatformToPlatform do
  use Ecto.Migration

  def change do
    rename table(:content_sources), :content_platform, to: :platform
    rename table(:content_sources), :id_in_content_platform, to: :id_in_platform
  end
end
