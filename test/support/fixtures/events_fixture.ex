defmodule Glossia.EventsFixture do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glossia.Localizations` context.
  """

  alias Glossia.Events.Event
  alias Glossia.Repo

  def event_fixture(attr \\ %{}) do
    attrs =
      if attr[:project_id] do
        attr
      else
        {:ok, project} = Glossia.ProjectsFixtures.project_fixture()
        attr |> Map.put(:project_id, project.id)
      end

    attrs = attrs |> Enum.into(default_build_args())
    Event.changeset(%Event{}, attrs) |> Repo.insert()
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
