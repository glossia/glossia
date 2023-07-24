defmodule Glossia.Translations.TranslationTest do
  use Glossia.DataCase

  alias Glossia.Repo
  alias Glossia.Translations.Translation

  describe "changeset" do
    test "validates the presence of commit_sha" do
      # Given
      attrs = %{}

      # When
      changeset = Translation.changeset(%Translation{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{commit_sha: ["can't be blank"]} = errors
    end

    test "validates the presence of repository_id" do
      # Given
      attrs = %{commit_sha: "1234567890"}

      # When
      changeset = Translation.changeset(%Translation{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{repository_id: ["can't be blank"]} = errors
    end

    test "validates the presence of vcs" do
      # Given
      attrs = %{commit_sha: "1234567890", repository_id: "1234567890"}

      # When
      changeset = Translation.changeset(%Translation{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{vcs: ["can't be blank"]} = errors
    end

    test "validates the presence of project_id" do
      # Given
      attrs = %{commit_sha: "1234567890", repository_id: "1234567890", vcs: :github}

      # When
      changeset = Translation.changeset(%Translation{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{project_id: ["can't be blank"]} = errors
    end

    test "validate the inclusion of vcs" do
      # Given
      attrs = %{
        commit_sha: "1234567890",
        repository_id: "1234567890",
        vcs: :gitlab,
        project_id: 1
      }

      # When
      changeset = Translation.changeset(%Translation{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{vcs: ["is invalid"]} = errors
    end

    test "validate the uniqueness of commit_sha, repository_id and vcs" do
      # Given
      {:ok, project} = Glossia.ProjectsFixtures.project_fixture()

      attrs = %{
        commit_sha: "1234567890",
        repository_id: "1234567890",
        vcs: :github,
        project_id: project.id
      }

      %Translation{} |> Translation.changeset(attrs) |> Repo.insert!()

      # When
      {:error, changeset} = %Translation{} |> Translation.changeset(attrs) |> Repo.insert()

      # Then
      errors = errors_on(changeset)
      assert %{commit_sha: ["has already been taken"]} = errors
    end
  end
end
