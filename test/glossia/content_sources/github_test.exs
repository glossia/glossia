defmodule Glossia.ContentSources.Platforms.GitHubTest do
  use ExUnit.Case, async: true
  import Glossia.ContentSources.Platforms.GitHub
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
      use_cassette "glossia/content_sources/github_test/get_most_recent_version",
        match_requests_on: [:request_body] do
        Glossia.ContentSources.Platforms.GitHub.get_most_recent_version("glossia/glossia")
      end

    # Then
    assert {:ok, "bc8cd1fa2e6bf523fdafc47559315056b8fbb209"} = response
  end

  test "get_versions returns the versions sorted from the most recent" do
    # Given/When
    response =
      use_cassette "glossia/content_sources/github_test/get_versions",
        match_requests_on: [:request_body] do
        Glossia.ContentSources.Platforms.GitHub.get_versions("glossia/glossia")
      end

    # Then
    assert {:ok, ["bc8cd1fa2e6bf523fdafc47559315056b8fbb209" | _]} = response
  end

  test "get_default_branch returns main" do
    # Given/When
    response =
      use_cassette "glossia/content_sources/github_test/get_default_branch",
        match_requests_on: [:request_body] do
        Glossia.ContentSources.Platforms.GitHub.get_default_branch("glossia/glossia")
      end

    # Then
    assert {:ok, "main"} = response
  end
end
