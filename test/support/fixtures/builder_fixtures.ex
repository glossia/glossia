defmodule Glossia.BuilderFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glossia.Translations` context.
  """

  alias Glossia.Repo

  def build_fixture(attr \\ %{}) do
    attrs =
      if attr[:project_id] do
        attr
      else
        project = Glossia.ProjectsFixtures.project_fixture()
        attr |> Map.put(:project_id, project.id)
      end

    attrs |> Enum.into(default_build_args()) |> Repo.insert()
  end

  defp default_build_args() do
    %{
      commit_sha: "123",
      repository_id: "glossia/glossia",
      vcs: :github,
      event: :git_push
    }
  end
end
