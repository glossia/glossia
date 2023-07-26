defmodule Glossia.BuildsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glossia.Translations` context.
  """

  alias Glossia.Builds.Build
  alias Glossia.Repo

  def build_fixture(attr \\ %{}) do
    attrs =
      if attr[:project_id] do
        attr
      else
        {:ok, project} = Glossia.ProjectsFixtures.project_fixture()
        attr |> Map.put(:project_id, project.id)
      end

    attrs = attrs |> Enum.into(default_build_args())
    Build.changeset(%Build{}, attrs) |> Repo.insert()
  end

  defp default_build_args() do
    %{
      git_commit_sha: "123",
      git_repository_id: "glossia/glossia",
      git_vcs: :github,
      event: :git_push
    }
  end
end
