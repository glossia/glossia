defmodule Glossia.Foundation.Builds.Core.BuildTest do
  use Glossia.DataCase

  alias Glossia.Foundation.Builds.Core.Build

  describe "changeset" do
    test "validates the presence of version" do
      # Given
      attrs = %{}

      # When
      changeset = Build.changeset(%Build{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{version: ["can't be blank"]} = errors
    end

    test "validates the presence of repository_id" do
      # Given
      attrs = %{version: "1234567890"}

      # When
      changeset = Build.changeset(%Build{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_source_id: ["can't be blank"]} = errors
    end

    test "validates the presence of vcs" do
      # Given
      attrs = %{version: "1234567890", content_source_id: "1234567890"}

      # When
      changeset = Build.changeset(%Build{}, attrs)

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
      changeset = Build.changeset(%Build{}, attrs)

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
      changeset = Build.changeset(%Build{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_source_platform: ["is invalid"]} = errors
    end

    test "validate the uniqueness of version, repository_id and vcs" do
      # Given
      {:ok, project} = Glossia.Foundation.ProjectsFixtures.project_fixture()

      attrs = %{
        type: :new_version,
        version: "1234567890",
        content_source_id: "1234567890",
        content_source_platform: :github,
        project_id: project.id
      }

      %Build{} |> Build.changeset(attrs) |> Repo.insert!()

      # When
      {:error, changeset} = %Build{} |> Build.changeset(attrs) |> Repo.insert()

      # Then
      errors = errors_on(changeset)
      assert %{version: ["has already been taken"]} = errors
    end
  end
end
