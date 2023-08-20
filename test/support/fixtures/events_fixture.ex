defmodule Glossia.EventsFixture do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glossia.Translations` context.
  """

  alias Glossia.Events.GitEvent
  alias Glossia.Repo

  def git_event_fixture(attr \\ %{}) do
    attrs =
      if attr[:project_id] do
        attr
      else
        {:ok, project} = Glossia.ProjectsFixtures.project_fixture()
        attr |> Map.put(:project_id, project.id)
      end

    attrs = attrs |> Enum.into(default_build_args())
    GitEvent.changeset(%GitEvent{}, attrs) |> Repo.insert()
  end

  defp default_build_args() do
    %{
      commit_sha: "123",
      vcs_id: "glossia/glossia",
      vcs_platform: :github,
      event: :push
    }
  end
end
