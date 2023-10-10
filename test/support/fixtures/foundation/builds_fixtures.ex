defmodule Glossia.Foundation.BuildsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glossia.Localizations` context.
  """

  alias Glossia.Foundation.Builds.Core.Build
  alias Glossia.Repo

  def build_fixture(attr \\ %{}) do
    attrs =
      if attr[:project_id] do
        attr
      else
        project = Glossia.Foundation.ProjectsFixtures.project_fixture()
        attr |> Map.put(:project_id, project.id)
      end

    attrs = attrs |> Enum.into(default_build_args())
    Build.changeset(%Build{}, attrs) |> Repo.insert()
  end

  defp default_build_args() do
    %{
      version: "123",
      content_source_id: "glossia/glossia",
      content_source_platform: :github,
      type: :push
    }
  end
end
