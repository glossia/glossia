defmodule Glossia.Repo.Migrations.RenameProjectsGitVcsToVcsPlatform do
  use Ecto.Migration

  def change do
    rename table("projects"), :git_vcs, to: :vcs_platform
  end
end
