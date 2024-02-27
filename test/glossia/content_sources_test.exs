defmodule Glossia.ContentSourcesTest do
  use Glossia.DataCase
  alias Glossia.ContentSources.ContentSource
  alias Glossia.ContentSources
  alias Glossia.ContentSourcesFixtures

  describe "get_content_source_by_id" do
    test "returns the content source if it exists" do
      # Given
      content_source = ContentSourcesFixtures.content_source_fixture()

      # When
      got = ContentSources.get_content_source_by_id(content_source.id)

      # Then
      assert got.id == content_source.id
    end

    test "returns nil if it doesn't exist" do
      # When
      got = ContentSources.get_content_source_by_id(Ecto.UUID.generate())

      # Then
      assert got == nil
    end
  end
end
