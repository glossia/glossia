defmodule Glossia.Events.GitEventTests do
  use Glossia.DataCase

  alias Glossia.Events.GitEvent

  describe "changeset" do
    test "validates the presence of commit_sha" do
      # Given
      attrs = %{}

      # When
      changeset = GitEvent.changeset(%GitEvent{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{commit_sha: ["can't be blank"]} = errors
    end

    test "validates the presence of repository_id" do
      # Given
      attrs = %{commit_sha: "1234567890"}

      # When
      changeset = GitEvent.changeset(%GitEvent{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_source_id: ["can't be blank"]} = errors
    end

    test "validates the presence of vcs" do
      # Given
      attrs = %{commit_sha: "1234567890", content_source_id: "1234567890"}

      # When
      changeset = GitEvent.changeset(%GitEvent{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_source_platform: ["can't be blank"]} = errors
    end

    test "validates the presence of project_id" do
      # Given
      attrs = %{
        commit_sha: "1234567890",
        content_source_id: "1234567890",
        content_source_platform: :github
      }

      # When
      changeset = GitEvent.changeset(%GitEvent{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{project_id: ["can't be blank"]} = errors
    end

    test "validate the inclusion of vcs" do
      # Given
      attrs = %{
        commit_sha: "1234567890",
        content_source_id: "1234567890",
        content_source_platform: :gitlab,
        project_id: 1,
        event: :push
      }

      # When
      changeset = GitEvent.changeset(%GitEvent{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_source_platform: ["is invalid"]} = errors
    end

    test "validate the uniqueness of commit_sha, repository_id and vcs" do
      # Given
      {:ok, project} = Glossia.ProjectsFixtures.project_fixture()

      attrs = %{
        commit_sha: "1234567890",
        content_source_id: "1234567890",
        content_source_platform: :github,
        project_id: project.id,
        event: :push
      }

      %GitEvent{} |> GitEvent.changeset(attrs) |> Repo.insert!()

      # When
      {:error, changeset} = %GitEvent{} |> GitEvent.changeset(attrs) |> Repo.insert()

      # Then
      errors = errors_on(changeset)
      assert %{commit_sha: ["has already been taken"]} = errors
    end
  end
end
