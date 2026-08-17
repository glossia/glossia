defmodule Glossia.Quality.PageAddressTest do
  use ExUnit.Case, async: true

  alias Glossia.Quality.PageAddress

  test "appends logical paths to locale base paths with URI semantics" do
    assert PageAddress.build("https://example.com", "/") == "https://example.com/"
    assert PageAddress.build("https://example.com/es", "/") == "https://example.com/es"

    assert PageAddress.build("https://example.com/es", "/docs/getting-started") ==
             "https://example.com/es/docs/getting-started"
  end
end
