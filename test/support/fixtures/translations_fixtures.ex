defmodule Glossia.TranslationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glossia.Translations` context.
  """

  alias Glossia.Repo
  alias Glossia.Translations.Translation

  def translation_fixture(attr \\ %{}) do
    attrs =
      if attr[:project_id] do
        attr
      else
        project = Glossia.ProjectsFixtures.project_fixture()
        attr |> Map.put(:project_id, project.id)
      end

    attrs |> Enum.into(default_translation_attrs()) |> Repo.insert()
  end

  def default_translation_attrs() do
    %{
      commit_sha: "123",
      repository_id: "glossia/glossia",
      vcs: :github
    }
  end
end
