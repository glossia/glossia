defmodule Glossia.ContentSources.GitHubTest do
  use ExUnit.Case
  import Glossia.ContentSources.GitHub
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch

  test "supports_versioning? returns true" do
    assert supports_versioning?() == true
  end

  test "version_term returns 'commit'" do
    assert version_term() == "commit"
  end

  test "get_most_recent_version returns the most recent version" do
    # Given/When
    response =
      use_cassette "glossia/content_sources/github_test/get_most_recent_version" do
        Glossia.ContentSources.GitHub.get_most_recent_version("glossia/glossia")
      end

    # Then
    assert "bc8cd1fa2e6bf523fdafc47559315056b8fbb209" == response
  end
end
