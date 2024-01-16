defmodule Glossia.ContentSources.ContentSourceTest do
  use ExUnit.Case
  import Glossia.ContentSources.GitHub

  test "supports_versioning? returns true" do
    assert supports_versioning?() == true
  end

  test "version_term returns 'commit'" do
    assert version_term() == "commit"
  end
end
