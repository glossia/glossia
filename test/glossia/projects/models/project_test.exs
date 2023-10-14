defmodule Glossia.Projects.ProjectTest do
  use Glossia.DataCase

  alias Glossia.Projects.Project

  describe "changeset" do
    test "validates that handle is required" do
      # Given
      project = %Project{}

      attrs = %{
        content_source_id: "glossia/glossia",
        content_source_platform: :github,
        account_id: 1
      }

      # When
      changeset = Project.changeset(project, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{handle: ["can't be blank"]} = errors
    end

    test "validates that repository_id is required" do
      # Given
      project = %Project{}
      attrs = %{handle: "glossia", content_source_platform: :github, account_id: 1}

      # When
      changeset = Project.changeset(project, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_source_id: ["can't be blank"]} = errors
    end

    test "validates that vcs is required" do
      # Given
      project = %Project{}
      attrs = %{handle: "glossia", content_source_id: "glossia/glossia", account_id: 1}

      # When
      changeset = Project.changeset(project, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_source_platform: ["can't be blank"]} = errors
    end

    test "validates that account_id is required" do
      # Given
      project = %Project{}

      attrs = %{
        handle: "glossia",
        content_source_id: "glossia/glossia",
        content_source_platform: :github
      }

      # When
      changeset = Project.changeset(project, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{account_id: ["can't be blank"]} = errors
    end

    test "validates that vcs is valid" do
      # Given
      project = %Project{}

      attrs = %{
        handle: "glossia",
        content_source_id: "glossia/glossia",
        content_source_platform: :invalid_vcs,
        account_id: 1
      }

      # When
      changeset = Project.changeset(project, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_source_platform: ["is invalid"]} = errors
    end

    test "validates that handle is alphanumeric" do
      # Given
      project = %Project{}

      attrs = %{
        handle: "invalid handle",
        content_source_id: "glossia/glossia",
        content_source_platform: :github,
        account_id: 1
      }

      # When
      changeset = Project.changeset(project, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{handle: ["must be alphanumeric"]} = errors
    end

    test "validates that the handle is more than 3 characters" do
      # Given
      project = %Project{}

      attrs = %{
        handle: "a",
        content_source_id: "glossia/glossia",
        content_source_platform: :github,
        account_id: 1
      }

      # When
      changeset = Project.changeset(project, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{handle: ["should be at least 3 character(s)"]} = errors
    end

    test "validates that the handle is less than 20 characters" do
      # Given
      project = %Project{}

      attrs = %{
        handle: "aasdgasgasgdasdgasdgasgasdgasgsags",
        content_source_id: "glossia/glossia",
        content_source_platform: :github,
        account_id: 1
      }

      # When
      changeset = Project.changeset(project, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{handle: ["should be at most 20 character(s)"]} = errors
    end

    test "validates the inclusion of content_source_platform in the supported types" do
      # Given
      project = %Project{}

      attrs = %{
        content_source_platform: :invalid
      }

      # When
      changeset = Project.changeset(project, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_source_platform: ["is invalid"]} = errors
    end
  end
end
