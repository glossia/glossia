defmodule Glossia.Projects.ProjectTest do
  use Glossia.DataCase

  alias Glossia.Projects.Project

  describe "changeset" do
    test "validates that handle is required" do
      # Given
      project = %Project{}
      attrs = %{repository_id: "glossia/glossia", vcs: :github, account_id: 1}

      # When
      changeset = Project.changeset(project, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{handle: ["can't be blank"]} = errors
    end

    test "validates that repository_id is required" do
      # Given
      project = %Project{}
      attrs = %{handle: "glossia", vcs: :github, account_id: 1}

      # When
      changeset = Project.changeset(project, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{repository_id: ["can't be blank"]} = errors
    end

    test "validates that vcs is required" do
      # Given
      project = %Project{}
      attrs = %{handle: "glossia", repository_id: "glossia/glossia", account_id: 1}

      # When
      changeset = Project.changeset(project, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{vcs: ["can't be blank"]} = errors
    end

    test "validates that account_id is required" do
      # Given
      project = %Project{}
      attrs = %{handle: "glossia", repository_id: "glossia/glossia", vcs: :github}

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
        repository_id: "glossia/glossia",
        vcs: :invalid_vcs,
        account_id: 1
      }

      # When
      changeset = Project.changeset(project, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{vcs: ["is invalid"]} = errors
    end

    test "validates that handle is alphanumeric" do
      # Given
      project = %Project{}

      attrs = %{
        handle: "invalid handle",
        repository_id: "glossia/glossia",
        vcs: :github,
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
        repository_id: "glossia/glossia",
        vcs: :github,
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
        repository_id: "glossia/glossia",
        vcs: :github,
        account_id: 1
      }

      # When
      changeset = Project.changeset(project, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{handle: ["should be at most 20 character(s)"]} = errors
    end
  end
end
