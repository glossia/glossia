defmodule Glossia.Events.EventTest do
  use Glossia.DataCase

  alias Glossia.Events.Event

  describe "changeset" do
    test "validates the presence of version" do
      # Given
      attrs = %{}

      # When
      changeset = Event.changeset(%Event{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{version: ["can't be blank"]} = errors
    end

    test "validates the presence of repository_id" do
      # Given
      attrs = %{version: "1234567890"}

      # When
      changeset = Event.changeset(%Event{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_source_id: ["can't be blank"]} = errors
    end

    test "validates the presence of vcs" do
      # Given
      attrs = %{version: "1234567890", content_source_id: "1234567890"}

      # When
      changeset = Event.changeset(%Event{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_source_platform: ["can't be blank"]} = errors
    end

    test "validates the presence of project_id" do
      # Given
      attrs = %{
        version: "1234567890",
        content_source_id: "1234567890",
        content_source_platform: :github
      }

      # When
      changeset = Event.changeset(%Event{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{project_id: ["can't be blank"]} = errors
    end

    test "validate the inclusion of vcs" do
      # Given
      attrs = %{
        version: "1234567890",
        content_source_id: "1234567890",
        content_source_platform: :gitlab,
        project_id: 1,
        type: :push
      }

      # When
      changeset = Event.changeset(%Event{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_source_platform: ["is invalid"]} = errors
    end

    test "validate the uniqueness of version, repository_id and vcs" do
      # Given
      {:ok, project} = Glossia.ProjectsFixtures.project_fixture()

      attrs = %{
        type: :new_version,
        version: "1234567890",
        content_source_id: "1234567890",
        content_source_platform: :github,
        project_id: project.id,
      }

      %Event{} |> Event.changeset(attrs) |> Repo.insert!()

      # When
      {:error, changeset} = %Event{} |> Event.changeset(attrs) |> Repo.insert()

      # Then
      errors = errors_on(changeset)
      assert %{version: ["has already been taken"]} = errors
    end
  end
end
