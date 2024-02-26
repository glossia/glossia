defmodule Glossia.ContentSources.ContentSourceTest do
  use Glossia.DataCase

  alias Glossia.ContentSources.ContentSource

  describe "changeset" do
    test "validates that id_in_content_platform is required" do
      # Given
      content_source = %ContentSource{}
      attrs = %{handle: "glossia", content_platform: :github, account_id: 1}

      # When
      changeset = ContentSource.changeset(content_source, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{id_in_content_platform: ["This attribute is required"]} = errors
    end

    test "validates that content_platform is required" do
      # Given
      content_source = %ContentSource{}

      attrs = %{
        handle: "glossia",
        id_in_content_platform: "glossia/glossia",
        account_id: 1
      }

      # When
      changeset = ContentSource.changeset(content_source, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_platform: ["This attribute is required"]} = errors
    end

    test "validates that account_id is required" do
      # Given
      content_source = %ContentSource{}

      attrs = %{
        handle: "glossia",
        id_in_content_platform: "glossia/glossia",
        content_platform: :github
      }

      # When
      changeset = ContentSource.changeset(content_source, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{account_id: ["This attribute is required"]} = errors
    end

    test "validates that content_platform is valid" do
      # Given
      content_source = %ContentSource{}

      attrs = %{
        id_in_content_platform: "glossia/glossia",
        content_platform: :invalid_vcs,
        account_id: 1
      }

      # When
      changeset = ContentSource.changeset(content_source, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_platform: ["is invalid"]} = errors
    end

    test "validates the inclusion of content_platform in the supported types" do
      # Given
      content_source = %ContentSource{}

      attrs = %{
        content_platform: :invalid
      }

      # When
      changeset = ContentSource.changeset(content_source, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{content_platform: ["is invalid"]} = errors
    end
  end
end
